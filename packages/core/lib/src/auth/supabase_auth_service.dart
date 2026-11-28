import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:core/src/auth/auth_configuration.dart';
import 'package:core/src/auth/auth_service.dart';
import 'package:core/src/auth/auth_session_source.dart';
import 'package:core/src/secure_storage/secure_storage.dart';
import 'package:core/src/auth/supabase_storage_adapter.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseAuthService implements AuthService {
  SupabaseAuthService({
    required this._configuration,
    SecureStorage? storage,
    AuthSessionStore? session,
    this._callbackLinks,
  }) : _storage = storage ?? SecureStorageImpl(),
       _session = session ?? AuthSessionStore();
  final SecureStorage _storage;
  final AuthSessionStore _session;
  AuthSessionSource get sessionSource => _session;
  String get _storageNamespace =>
      'shared-expenses:${_configuration.environment.name}:${Uri.parse(_configuration.url).host}';

  final AuthConfiguration _configuration;
  Supabase? _supabase;
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

  AuthenticationProfile? get _currentProfile {
    final user = _supabase?.client.auth.currentSession?.user;
    if (user == null) return null;
    final metadata = user.userMetadata;
    String? text(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : null;
    return AuthenticationProfile(
      name: text(metadata?['full_name']) ?? text(metadata?['name']),
      email: text(user.email),
    );
  }

  @override
  Future<void> initialize() => _disposed ? Future.value() : _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (_configuration.isEmpty) return;
    if (!_configuration.isValid) {
      _publishFailure(const AuthenticationFailure(AuthenticationFailureKind.configuration));
      return;
    }
    final storage = SupabaseStorageAdapter(namespace: _storageNamespace, storage: _storage);
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
      await _publishStoredSession();
      _sessionSubscription = _supabase!.client.auth.onAuthStateChange.listen((_) {
        _sessionNotifications = _sessionNotifications.then((_) => _publishStoredSession());
      }, onError: (Object error, StackTrace stack) => _publishFailure(_mapFailure(error)));
      _linkSubscription = (_callbackLinks ?? AppLinks().uriLinkStream).listen(
        _handleCallback,
        onError: (Object error, StackTrace stack) => _publishFailure(_mapFailure(error)),
      );
    } on Object catch (error) {
      _publishFailure(_mapFailure(error));
    }
  }

  Future<void> _publishStoredSession() async {
    try {
      await _storage.flush();
      if (!_acceptCallbacks && _sessionStatus == AuthenticationStatus.signedIn) return;
      _session.update(_sessionStatus, profile: _currentProfile);
    } on SecureStorageFailure {
      _publishFailure(const AuthenticationFailure(AuthenticationFailureKind.storage));
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
    if (error is SecureStorageFailure) return const AuthenticationFailure(AuthenticationFailureKind.storage);
    if (error is AuthException && (error.code == 'access_denied' || error.code == 'user_cancelled')) {
      return const AuthenticationFailure(AuthenticationFailureKind.cancelled);
    }
    return const AuthenticationFailure(AuthenticationFailureKind.connection);
  }

  void _publishFailure(AuthenticationFailure failure) =>
      _session.update(_sessionStatus, failure: failure, profile: _currentProfile);

  @override
  Future<Either<AuthenticationFailure, Unit>> launchSignIn({required AuthSource source}) async {
    final supabase = _supabase;
    if (supabase == null) return const Left(AuthenticationFailure(AuthenticationFailureKind.configuration));
    try {
      await _signOutOperation;
      await _callbackQueue;
      _acceptCallbacks = true;
      _session.update(_sessionStatus, profile: _currentProfile);
      final launched = await supabase.client.auth.signInWithOAuth(
        switch (source) {
          AuthSource.google => OAuthProvider.google,
        },
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
      await _storage.delete('$_storageNamespace:session');
      await supabase.client.auth.signOut(scope: SignOutScope.local);
      await _storage.flush();
      _session.update(_sessionStatus, profile: _currentProfile);
      return const Right(unit);
    } on Object catch (error) {
      // The SDK clears local auth before attempting remote token revocation.
      if (supabase.client.auth.currentSession == null) {
        try {
          await _storage.flush();
          _session.update(_sessionStatus, profile: _currentProfile);
          return const Right(unit);
        } on SecureStorageFailure {
          /* Report failed persistence below. */
        }
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
    await _storage.flush().catchError((Object _) {});
    await _supabase?.dispose();
    await _session.close();
  }
}
