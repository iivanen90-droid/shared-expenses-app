import 'dart:async';

import 'package:core/src/auth/auth_configuration.dart';
import 'package:core/src/auth/auth_service.dart';
import 'package:core/src/auth/secure_auth_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseAuthService implements AuthService {
  SupabaseAuthService({required this._configuration});

  final AuthConfiguration _configuration;
  final _updates = StreamController<Either<AuthenticationFailure, AuthenticationStatus>>.broadcast();
  AuthenticationStatus _status = AuthenticationStatus.unconfigured;
  AuthenticationFailure? _failure;
  Supabase? _supabase;
  SecureAuthStorage? _storage;
  StreamSubscription<AuthState>? _subscription;
  Future<void>? _initialization;
  Future<void> _eventQueue = Future.value();
  bool _acceptCallbacks = true;
  bool _disposed = false;

  @override
  Future<void> initialize() => _disposed ? Future.value() : _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (_configuration.isEmpty) return;
    if (!_configuration.isValid) {
      _failure = const AuthenticationFailure(AuthenticationFailureKind.configuration);
      return;
    }
    final storage = SecureAuthStorage(
      namespace: 'shared-expenses:${_configuration.environment.name}:${Uri.parse(_configuration.url).host}',
    );
    _storage = storage;
    try {
      await storage.accessToken();
      _supabase = await Supabase.initialize(
        url: _configuration.url,
        publishableKey: _configuration.publishableKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: storage,
          pkceAsyncStorage: storage,
          detectSessionInUriPredicate: (uri) => _acceptCallbacks && _configuration.acceptsCallback(uri),
        ),
      );
      await storage.pending;
      if (storage.writeFailed) {
        _failure = const AuthenticationFailure(AuthenticationFailureKind.storage);
      }
      _status = _sessionStatus;
      _subscription = _supabase!.client.auth.onAuthStateChange.listen((_) {
        _eventQueue = _eventQueue.then((_) async {
          await storage.pending;
          if (storage.writeFailed) {
            _publishFailure(const AuthenticationFailure(AuthenticationFailureKind.storage));
            return;
          }
          _failure = null;
          _status = _sessionStatus;
          _updates.add(Right(_status));
        });
      }, onError: (Object error, StackTrace stack) => _publishFailure(_mapFailure(error)));
    } on Object catch (error) {
      _failure = _mapFailure(error);
    }
  }

  AuthenticationStatus get _sessionStatus {
    final session = _supabase?.client.auth.currentSession;
    return session != null && !session.isExpired ? AuthenticationStatus.signedIn : AuthenticationStatus.signedOut;
  }

  AuthenticationFailure _mapFailure(Object error) {
    if (error is AuthenticationFailure) return error;
    if (error is AuthException && (error.code == 'access_denied' || error.code == 'user_cancelled')) {
      return const AuthenticationFailure(AuthenticationFailureKind.cancelled);
    }
    return const AuthenticationFailure(AuthenticationFailureKind.connection);
  }

  void _publishFailure(AuthenticationFailure failure) {
    _failure = failure;
    _updates.add(Left(failure));
  }

  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => Stream.multi((listener) {
    final subscription = _updates.stream.listen(listener.add, onDone: listener.close);
    listener.add(_failure == null ? Right(_status) : Left(_failure!));
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() async {
    final supabase = _supabase;
    if (supabase == null) return const Left(AuthenticationFailure(AuthenticationFailureKind.configuration));
    try {
      _acceptCallbacks = true;
      final launched = await supabase.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _configuration.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: const {'prompt': 'select_account'},
      );
      return launched ? const Right(unit) : const Left(AuthenticationFailure(AuthenticationFailureKind.connection));
    } on Object catch (error) {
      return Left(_mapFailure(error));
    }
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() async {
    final supabase = _supabase;
    if (supabase == null) return const Left(AuthenticationFailure(AuthenticationFailureKind.configuration));
    try {
      _acceptCallbacks = false;
      // Clear the saved session before reporting success, including when offline.
      await _storage!.removePersistedSession();
      await supabase.client.auth.signOut(scope: SignOutScope.local);
      return const Right(unit);
    } on Object catch (error) {
      // The SDK clears local auth before attempting remote token revocation.
      if (supabase.client.auth.currentSession == null && _storage?.writeFailed == false) {
        return const Right(unit);
      }
      return Left(_mapFailure(error));
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _initialization;
    await _subscription?.cancel();
    await _eventQueue;
    await _storage?.pending;
    await _supabase?.dispose();
    await _updates.close();
  }
}
