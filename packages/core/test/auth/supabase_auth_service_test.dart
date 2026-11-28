import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:core/src/auth/supabase_storage_adapter.dart';
import 'package:core/src/auth/supabase_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/secure_storage_backend.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('profile uses current SDK identity and disappears after sign-out', () async {
    final harness = await _AuthHarness.create();
    try {
      expect(harness.service.sessionSource.currentProfile, isNull);
      await harness.startCallback();
      final data = jsonDecode(_sessionResponse().body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      user['email'] = 'test@example.invalid';
      user['user_metadata'] = {'full_name': '  Test Person  '};
      harness.response.complete(http.Response(jsonEncode(data), 200));
      await harness.service.sessionSource.watchChanges().firstWhere(
        (account) => account.session == AuthenticationStatus.signedIn,
      );
      expect(harness.service.sessionSource.currentProfile?.name, 'Test Person');
      expect(harness.service.sessionSource.currentProfile?.email, 'test@example.invalid');
      expect(harness.service.sessionSource.currentProfile.toString(), isNot(contains('test@example.invalid')));
      await harness.service.signOut();
      expect(harness.service.sessionSource.currentProfile, isNull);
    } finally {
      await harness.dispose();
    }
  });

  test('unreadable storage fails before SDK initialization and a later service can start cleanly', () async {
    final backend = TestSecureStorageBackend()..failSessionReads = true;
    final secure = SecureStorageImpl(storage: backend);
    const configuration = AuthConfiguration(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_test',
      environment: EnvironmentType.dev,
    );
    final service = SupabaseAuthService(
      configuration: configuration,
      storage: secure,
      callbackLinks: const Stream.empty(),
    );
    try {
      await service.initialize();
      expect(service.sessionSource.current.session, AuthenticationStatus.unconfigured);
      expect(service.sessionSource.current.failure?.kind, AuthenticationFailureKind.storage);
      // Failed initialization must not leave a global SDK instance behind.
      expect(() => Supabase.instance, throwsAssertionError);
    } finally {
      await service.dispose();
    }

    backend.failSessionReads = false;
    final recovered = SupabaseAuthService(
      configuration: configuration,
      storage: secure,
      callbackLinks: const Stream.empty(),
    );
    try {
      await recovered.initialize();
      expect(recovered.sessionSource.current.session, AuthenticationStatus.signedOut);
    } finally {
      await recovered.dispose();
    }
  });

  test('cancel waits for an in-flight PKCE exchange and clears its late session before success', () async {
    final harness = await _AuthHarness.create();
    final events = <AuthenticationSnapshot>[];
    final subscription = harness.service.sessionSource.watchChanges().listen(events.add);
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
      await harness.secure.flush();
      await Future<void>.delayed(Duration.zero);
      expect(harness.supabase.client.auth.currentSession, isNull);
      expect(await harness.storage.accessToken(), isNull);
      expect(events.any((event) => event.session == AuthenticationStatus.signedIn), isFalse);

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
    final backend = TestSecureStorageBackend();
    final harness = await _AuthHarness.create(backend: backend);
    final events = <AuthenticationSnapshot>[];
    final subscription = harness.service.sessionSource.watchChanges().listen(events.add);
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
      expect(events.last.session, AuthenticationStatus.signedIn);
      expect(events.last.failure != null, isTrue);
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
    final events = <AuthenticationSnapshot>[];
    final subscription = harness.service.sessionSource.watchChanges().listen(events.add);
    try {
      await harness.startCallback();
      final cancelling = harness.service.signOut();
      harness.response.complete(
        http.Response(jsonEncode({'error': 'invalid_grant', 'error_description': 'test-only provider failure'}), 400),
      );
      expect((await cancelling).isRight(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(events.any((event) => event.failure != null), isFalse);
      expect(await harness.storage.accessToken(), isNull);
    } finally {
      await subscription.cancel();
      await harness.dispose();
    }
  });

  test('snapshot preserves the active session after an auth stream error without replaying it', () async {
    final harness = await _AuthHarness.create();
    try {
      final signedIn = harness.service.sessionSource.watchChanges().firstWhere(
        (event) => event.session == AuthenticationStatus.signedIn,
      );
      await harness.startCallback();
      harness.response.complete(_sessionResponse());
      await signedIn;
      harness.supabase.client.auth.currentSession!.expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;
      final failure = harness.service.sessionSource.watchChanges().firstWhere((event) => event.failure != null);
      // Inject the same SDK stream event delivered by a failed background token refresh.
      // ignore: invalid_use_of_internal_member
      harness.supabase.client.auth.notifyException(
        const AuthException('test-only refresh failure'),
        StackTrace.current,
      );
      await failure;
      expect(harness.service.sessionSource.current.session, AuthenticationStatus.signedIn);
      expect(harness.service.sessionSource.current.failure?.kind, AuthenticationFailureKind.connection);
      final freshEvents = <AuthenticationSnapshot>[];
      final freshSubscription = harness.service.sessionSource.watchChanges().listen(freshEvents.add);
      await Future<void>.delayed(Duration.zero);
      expect(freshEvents, isEmpty);
      await freshSubscription.cancel();
      expect((await harness.service.signOut()).isRight(), isTrue);
      expect(await harness.storage.accessToken(), isNull);
    } finally {
      await harness.dispose();
    }
  });

  test('an existing subscriber receives the active session when secure persistence fails', () async {
    final backend = TestSecureStorageBackend();
    final harness = await _AuthHarness.create(backend: backend);
    final events = <AuthenticationSnapshot>[];
    final subscription = harness.service.sessionSource.watchChanges().listen(events.add);
    try {
      final failure = harness.service.sessionSource.watchChanges().firstWhere((event) => event.failure != null);
      await harness.startCallback();
      backend.failSessionWrites = true;
      harness.response.complete(_sessionResponse());
      final error = await failure;
      expect(error.failure?.kind, AuthenticationFailureKind.storage);
      expect(events.last.session, AuthenticationStatus.signedIn);
      expect(events.last.failure != null, isTrue);
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
      final signedIn = first.service.sessionSource.watchChanges().firstWhere(
        (event) => event.session == AuthenticationStatus.signedIn,
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
      expect(reopened.service.sessionSource.current.session, AuthenticationStatus.signedIn);
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
  _AuthHarness({FlutterSecureStorage? backend}) : secure = SecureStorageImpl(storage: backend);
  final SecureStorage secure;
  late final storage = SupabaseStorageAdapter(namespace: 'test-auth-project', storage: secure);
  final links = StreamController<Uri>.broadcast();
  final requested = Completer<void>();
  final response = Completer<http.Response>();
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
      storage: harness.secure,
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
