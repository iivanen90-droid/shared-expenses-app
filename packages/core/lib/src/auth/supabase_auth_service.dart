import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:core/src/auth/auth_configuration.dart';
import 'package:core/src/auth/auth_service.dart';
import 'package:core/src/auth/secure_auth_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseAuthService implements AuthService {
  SupabaseAuthService({required this._configuration, this._storage, this._callbackLinks});

  final AuthConfiguration _configuration;
  final _updates = StreamController<Either<AuthenticationFailure, AuthenticationStatus>>.broadcast();
  AuthenticationStatus _status = AuthenticationStatus.unconfigured;
  AuthenticationFailure? _failure;
  Supabase? _supabase;
  SecureAuthStorage? _storage;
  StreamSubscription<AuthState>? _subscription;
  final Stream<Uri>? _callbackLinks;
  StreamSubscription<Uri>? _linkSubscription;
  Future<void>? _initialization;
  Future<void> _eventQueue = Future.value();
  Future<void> _callbackQueue = Future.value();
  Future<Either<AuthenticationFailure, Unit>>? _signOutOperation;
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
    final storage =
        _storage ??
        SecureAuthStorage(
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
          detectSessionInUri: false,
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
          if (!_acceptCallbacks && _supabase?.client.auth.currentSession != null) return;
          if (storage.writeFailed) {
            _publishFailure(const AuthenticationFailure(AuthenticationFailureKind.storage));
            return;
          }
          _failure = null;
          _status = _sessionStatus;
          _updates.add(Right(_status));
        });
      }, onError: (Object error, StackTrace stack) => _publishFailure(_mapFailure(error)));
      _linkSubscription = (_callbackLinks ?? AppLinks().uriLinkStream).listen(
        _handleCallback,
        onError: (Object error, StackTrace stack) => _publishFailure(_mapFailure(error)),
      );
    } on Object catch (error) {
      _failure = _mapFailure(error);
    }
  }

  void _handleCallback(Uri uri) {
    if (!_acceptCallbacks || !_configuration.acceptsCallback(uri)) return;
    _callbackQueue = _callbackQueue.then((_) async {
      if (!_acceptCallbacks) return;
      try {
        await _supabase!.client.auth.getSessionFromUrl(uri);
      } on Object catch (error) {
        if (_acceptCallbacks) _publishFailure(_mapFailure(error));
      }
    });
  }

  AuthenticationStatus get _sessionStatus {
    // A saved identity must remain removable even when its token needs refresh.
    return _supabase?.client.auth.currentSession == null
        ? AuthenticationStatus.signedOut
        : AuthenticationStatus.signedIn;
  }

  AuthenticationFailure _mapFailure(Object error) {
    if (error is AuthenticationFailure) return error;
    if (error is AuthException && (error.code == 'access_denied' || error.code == 'user_cancelled')) {
      return const AuthenticationFailure(AuthenticationFailureKind.cancelled);
    }
    return const AuthenticationFailure(AuthenticationFailureKind.connection);
  }

  void _publishFailure(AuthenticationFailure failure) {
    if (_supabase != null && _signOutOperation == null) {
      _status = _sessionStatus;
      _updates.add(Right(_status));
    }
    _failure = failure;
    _updates.add(Left(failure));
  }

  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => Stream.multi((listener) {
    final subscription = _updates.stream.listen(listener.add, onDone: listener.close);
    // Replay session presence before an error so a reopened page can still sign out.
    final session = _supabase != null && _signOutOperation == null ? _sessionStatus : _status;
    listener.add(Right(session));
    final failure = _failure;
    if (failure != null) listener.add(Left(failure));
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() async {
    final supabase = _supabase;
    if (supabase == null) return const Left(AuthenticationFailure(AuthenticationFailureKind.configuration));
    try {
      await _signOutOperation;
      await _callbackQueue;
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
  Future<Either<AuthenticationFailure, Unit>> signOut() =>
      _signOutOperation ??= _signOut().whenComplete(() => _signOutOperation = null);

  Future<Either<AuthenticationFailure, Unit>> _signOut() async {
    final supabase = _supabase;
    if (supabase == null) return const Left(AuthenticationFailure(AuthenticationFailureKind.configuration));
    try {
      _acceptCallbacks = false;
      // The SDK can still save an in-flight exchange after signOut. Drain it first,
      // suppress its UI events, then clear the resulting session before success.
      await _callbackQueue;
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
    await _linkSubscription?.cancel();
    await _callbackQueue;
    await _signOutOperation;
    await _subscription?.cancel();
    await _eventQueue;
    await _storage?.pending;
    await _supabase?.dispose();
    await _updates.close();
  }
}
