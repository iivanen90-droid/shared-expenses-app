import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:core/src/auth/secure_auth_storage.dart';
import 'package:core/src/auth/supabase_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('cancel waits for an in-flight PKCE exchange and clears its late session before success', () async {
    final harness = await _AuthHarness.create();
    final events = <Either<AuthenticationFailure, AuthenticationStatus>>[];
    final subscription = harness.service.watchStatus().listen(events.add);
    try {
      await harness.startCallback();
      var cancelled = false;
      final cancelling = harness.service.signOut().then((result) {
        cancelled = true;
        return result;
      });
      await Future<void>.delayed(Duration.zero);
      expect(cancelled, isFalse);
      harness.response.complete(_sessionResponse());
      expect((await cancelling).isRight(), isTrue);
      await harness.storage.pending;
      await Future<void>.delayed(Duration.zero);
      expect(harness.supabase.client.auth.currentSession, isNull);
      expect(await harness.storage.accessToken(), isNull);
      expect(
        events.any(
          (event) => event.getOrElse((_) => AuthenticationStatus.unconfigured) == AuthenticationStatus.signedIn,
        ),
        isFalse,
      );

      // An additional callback received after cancellation must not create another request.
      harness.links.add(Uri.parse('sharedexpenses-dev://auth-callback?code=late-code'));
      await Future<void>.delayed(Duration.zero);
      expect(harness.tokenRequests, 1);
    } finally {
      await subscription.cancel();
      await harness.dispose();
    }
  });

  test('failed cancellation publishes its actual active session and permits a cleanup retry', () async {
    final backend = _FailingSessionStorage();
    final harness = await _AuthHarness.create(backend: backend);
    final events = <Either<AuthenticationFailure, AuthenticationStatus>>[];
    final subscription = harness.service.watchStatus().listen(events.add);
    try {
      await harness.startCallback();
      backend.failSessionDeletes = true;
      final cancelling = harness.service.signOut();
      harness.response.complete(_sessionResponse());
      final result = await cancelling;
      await Future<void>.delayed(Duration.zero);
      expect(result.getLeft().toNullable()?.kind, AuthenticationFailureKind.storage);
      expect(harness.supabase.client.auth.currentSession, isNotNull);
      expect(await harness.storage.hasAccessToken(), isTrue);
      expect(
        events[events.length - 2].getOrElse((_) => AuthenticationStatus.unconfigured),
        AuthenticationStatus.signedIn,
      );
      expect(events.last.isLeft(), isTrue);
      backend.failSessionDeletes = false;
      expect((await harness.service.signOut()).isRight(), isTrue);
      expect(harness.supabase.client.auth.currentSession, isNull);
      expect(await harness.storage.accessToken(), isNull);
    } finally {
      await subscription.cancel();
      await harness.dispose();
    }
  });

  test('a failed in-flight exchange also completes cancellation without surfacing its obsolete error', () async {
    final harness = await _AuthHarness.create();
    final events = <Either<AuthenticationFailure, AuthenticationStatus>>[];
    final subscription = harness.service.watchStatus().listen(events.add);
    try {
      await harness.startCallback();
      final cancelling = harness.service.signOut();
      harness.response.complete(
        http.Response(jsonEncode({'error': 'invalid_grant', 'error_description': 'test-only provider failure'}), 400),
      );
      expect((await cancelling).isRight(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(events.any((event) => event.isLeft()), isFalse);
      expect(await harness.storage.accessToken(), isNull);
    } finally {
      await subscription.cancel();
      await harness.dispose();
    }
  });

  test('a new subscriber receives the active session even after an auth stream error', () async {
    final harness = await _AuthHarness.create();
    try {
      final signedIn = harness.service.watchStatus().firstWhere(
        (event) => event.getOrElse((_) => AuthenticationStatus.unconfigured) == AuthenticationStatus.signedIn,
      );
      await harness.startCallback();
      harness.response.complete(_sessionResponse());
      await signedIn;
      harness.supabase.client.auth.currentSession!.expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;
      final failure = harness.service.watchStatus().firstWhere((event) => event.isLeft());
      // Inject the same SDK stream event delivered by a failed background token refresh.
      // ignore: invalid_use_of_internal_member
      harness.supabase.client.auth.notifyException(
        const AuthException('test-only refresh failure'),
        StackTrace.current,
      );
      await failure;
      final reopened = await harness.service.watchStatus().take(2).toList();
      expect(reopened.first.getOrElse((_) => AuthenticationStatus.unconfigured), AuthenticationStatus.signedIn);
      expect(reopened.last.isLeft(), isTrue);
      expect((await harness.service.signOut()).isRight(), isTrue);
      expect(await harness.storage.accessToken(), isNull);
    } finally {
      await harness.dispose();
    }
  });

  test('an existing subscriber receives the active session when secure persistence fails', () async {
    final backend = _FailingSessionStorage();
    final harness = await _AuthHarness.create(backend: backend);
    final events = <Either<AuthenticationFailure, AuthenticationStatus>>[];
    final subscription = harness.service.watchStatus().listen(events.add);
    try {
      final failure = harness.service.watchStatus().firstWhere((event) => event.isLeft());
      await harness.startCallback();
      backend.failSessionWrites = true;
      harness.response.complete(_sessionResponse());
      final error = await failure;
      expect(error.getLeft().toNullable()?.kind, AuthenticationFailureKind.storage);
      expect(
        events[events.length - 2].getOrElse((_) => AuthenticationStatus.unconfigured),
        AuthenticationStatus.signedIn,
      );
      expect(events.last.isLeft(), isTrue);
      expect(harness.supabase.client.auth.currentSession, isNotNull);
      expect(await harness.storage.accessToken(), isNull);
      backend.failSessionWrites = false;
      expect((await harness.service.signOut()).isRight(), isTrue);
      expect(harness.supabase.client.auth.currentSession, isNull);
    } finally {
      await subscription.cancel();
      await harness.dispose();
    }
  });

  test('a completed SDK session is saved, restored by a new service and removed by sign-out', () async {
    final first = await _AuthHarness.create();
    try {
      final signedIn = first.service.watchStatus().firstWhere(
        (event) => event.getOrElse((_) => AuthenticationStatus.unconfigured) == AuthenticationStatus.signedIn,
      );
      await first.startCallback();
      first.response.complete(_sessionResponse());
      await signedIn;
      expect(await first.storage.hasAccessToken(), isTrue);
    } finally {
      await first.dispose();
    }

    final reopened = await _AuthHarness.create();
    try {
      final status = await reopened.service.watchStatus().first;
      expect(status.getOrElse((_) => AuthenticationStatus.unconfigured), AuthenticationStatus.signedIn);
      expect((await reopened.service.signOut()).isRight(), isTrue);
      expect(await reopened.storage.accessToken(), isNull);
      expect(reopened.supabase.client.auth.currentSession, isNull);
    } finally {
      await reopened.dispose();
    }
  });
}

http.Response _sessionResponse() {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': '00000000-0000-0000-0000-000000000001',
            'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            'aud': 'authenticated',
          }),
        ),
      )
      .replaceAll('=', '');
  return http.Response(
    jsonEncode({
      'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.dGVzdA',
      'refresh_token': 'test-only-refresh-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': '00000000-0000-0000-0000-000000000001',
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
    200,
  );
}

class _AuthHarness {
  _AuthHarness({FlutterSecureStorage? backend})
    : storage = SecureAuthStorage(namespace: 'test-auth-project', storage: backend);
  final links = StreamController<Uri>.broadcast();
  final requested = Completer<void>();
  final response = Completer<http.Response>();
  final SecureAuthStorage storage;
  late final Supabase supabase;
  late final SupabaseAuthService service;
  int tokenRequests = 0;

  static Future<_AuthHarness> create({FlutterSecureStorage? backend}) async {
    final harness = _AuthHarness(backend: backend);
    const configuration = AuthConfiguration(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_test',
      environment: EnvironmentType.dev,
    );
    harness.supabase = await Supabase.initialize(
      url: configuration.url,
      publishableKey: configuration.publishableKey,
      debug: false,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/token')) {
          harness.tokenRequests++;
          if (!harness.requested.isCompleted) harness.requested.complete();
          return harness.response.future;
        }
        return http.Response('', 204);
      }),
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: false,
        localStorage: harness.storage,
        pkceAsyncStorage: harness.storage,
      ),
    );
    harness.service = SupabaseAuthService(
      configuration: configuration,
      storage: harness.storage,
      callbackLinks: harness.links.stream,
    );
    await harness.service.initialize();
    return harness;
  }

  Future<void> startCallback() async {
    await supabase.client.auth.getOAuthSignInUrl(provider: OAuthProvider.google);
    links.add(Uri.parse('sharedexpenses-dev://auth-callback?code=test-code'));
    await requested.future;
  }

  Future<void> dispose() async {
    await service.dispose();
    await links.close();
  }
}

class _FailingSessionStorage extends FlutterSecureStorage {
  bool failSessionWrites = false;
  bool failSessionDeletes = false;

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failSessionDeletes && key.endsWith(':session')) {
      throw StateError('test-only secure delete failure');
    }
    await super.delete(
      key: key,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failSessionWrites && key.endsWith(':session')) {
      throw StateError('test-only secure storage failure');
    }
    await super.write(
      key: key,
      value: value,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }
}
