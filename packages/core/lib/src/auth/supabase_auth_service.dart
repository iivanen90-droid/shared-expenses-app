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
  AuthenticationFailure? _failure;
  Supabase? _supabase;
  SecureAuthStorage? _storage;
  StreamSubscription<AuthState>? _sessionSubscription;
  final Stream<Uri>? _callbackLinks;
  StreamSubscription<Uri>? _linkSubscription;
  Future<void>? _initialization;
  // SDK notifications wait for storage; callback exchanges are drained before sign-out.
  Future<void> _sessionNotifications = Future.value();
  Future<void> _callbackQueue = Future.value();
  Future<Either<AuthenticationFailure, Unit>>? _signOutOperation;
  bool _acceptCallbacks = true;
  bool _disposed = false;

  // Database access shares the initialized client and its authenticated session.
  SupabaseClient? get client => _supabase?.client;

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
      // Fail before the SDK creates its global instance if secure storage is unreadable.
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
      _sessionSubscription = _supabase!.client.auth.onAuthStateChange.listen((_) {
        _sessionNotifications = _sessionNotifications.then((_) async {
          await storage.pending;
          if (!_acceptCallbacks && _supabase?.client.auth.currentSession != null) return;
          if (storage.writeFailed) {
            _publishFailure(const AuthenticationFailure(AuthenticationFailureKind.storage));
            return;
          }
          _failure = null;
          _updates.add(Right(_sessionStatus));
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
    if (_supabase == null) return AuthenticationStatus.unconfigured;
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
    _failure = failure;
    if (_supabase != null) {
      _updates.add(Right(_sessionStatus));
    }
    _updates.add(Left(failure));
  }

  @override
  AuthenticationSnapshot get snapshot => (session: _sessionStatus, failure: _failure);

  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => _updates.stream;

  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() async {
    final supabase = _supabase;
    if (supabase == null) return const Left(AuthenticationFailure(AuthenticationFailureKind.configuration));
    try {
      await _signOutOperation;
      await _callbackQueue;
      _acceptCallbacks = true;
      _failure = null;
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
      final failure = _mapFailure(error);
      _publishFailure(failure);
      return Left(failure);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _initialization;
    await _linkSubscription?.cancel();
    await _callbackQueue;
    await _signOutOperation;
    await _sessionSubscription?.cancel();
    await _sessionNotifications;
    await _storage?.pending;
    await _supabase?.dispose();
    await _updates.close();
  }
}
