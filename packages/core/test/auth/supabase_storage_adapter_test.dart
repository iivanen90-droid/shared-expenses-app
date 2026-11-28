import 'dart:async';

import 'package:core/core.dart';
import 'package:core/src/auth/supabase_storage_adapter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/secure_storage_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('SDK session and verifier remain encrypted-store backed and namespaced', () async {
    final secure = SecureStorageImpl();
    final storage = SupabaseStorageAdapter(namespace: 'dev:project', storage: secure);
    await storage.persistSession('private-session');
    await storage.setItem(key: 'verifier', value: 'private-verifier');
    final reopened = SupabaseStorageAdapter(namespace: 'dev:project', storage: secure);
    expect(await reopened.accessToken(), 'private-session');
    expect(await reopened.getItem(key: 'verifier'), 'private-verifier');
    expect(await SupabaseStorageAdapter(namespace: 'prod:project', storage: secure).accessToken(), isNull);
    await reopened.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('generic secure storage orders a delayed write before deletion', () async {
    final backend = TestSecureStorageBackend()..writeGate = Completer<void>();
    final secure = SecureStorageImpl(storage: backend);
    final writing = secure.write('dev:session', 'private-session');
    final removing = secure.delete('dev:session');
    backend.writeGate!.complete();
    await Future.wait([writing, removing]);
    await secure.flush();
    expect(await secure.read('dev:session'), isNull);
  });

  test('generic secure storage sanitizes failures and tracks failed keys until repaired', () async {
    final backend = TestSecureStorageBackend()..failSessionWrites = true;
    final secure = SecureStorageImpl(storage: backend);
    await expectLater(secure.write('dev:session', 'private-session'), throwsA(isA<SecureStorageFailure>()));
    await expectLater(secure.flush(), throwsA(isA<SecureStorageFailure>()));
    await secure.write('dev:verifier', 'private-verifier');
    await expectLater(secure.flush(), throwsA(isA<SecureStorageFailure>()));
    backend.failSessionWrites = false;
    await secure.write('dev:session', 'new-session');
    await secure.flush();
    expect(await secure.read('dev:session'), 'new-session');
    backend.failSessionReads = true;
    await expectLater(secure.read('dev:session'), throwsA(isA<SecureStorageFailure>()));
  });
}
