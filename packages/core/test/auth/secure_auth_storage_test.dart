import 'dart:async';

import 'package:core/core.dart';
import 'package:core/src/auth/secure_auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session and PKCE verifier survive a new storage instance and remain namespaced', () async {
    final backend = _MemoryStorage();
    final storage = SecureAuthStorage(namespace: 'dev:project', storage: backend);
    await storage.initialize();
    await storage.persistSession('private-session');
    await storage.setItem(key: 'verifier', value: 'private-verifier');
    final reopened = SecureAuthStorage(namespace: 'dev:project', storage: backend);
    expect(await reopened.hasAccessToken(), isTrue);
    expect(await reopened.accessToken(), 'private-session');
    expect(await reopened.getItem(key: 'verifier'), 'private-verifier');
    expect(await SecureAuthStorage(namespace: 'prod:project', storage: backend).accessToken(), isNull);
    await reopened.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('sign-out waits for an earlier token write and clears the saved session last', () async {
    final backend = _MemoryStorage()..writeGate = Completer<void>();
    final storage = SecureAuthStorage(namespace: 'dev:project', storage: backend);
    final writing = storage.persistSession('private-session');
    final removing = storage.removePersistedSession();
    backend.writeGate!.complete();
    await Future.wait([writing, removing]);
    expect(await storage.accessToken(), isNull);
  });

  test('storage errors are sanitized and a failed write does not poison later operations', () async {
    final backend = _MemoryStorage()..fail = true;
    final storage = SecureAuthStorage(namespace: 'dev:project', storage: backend);
    await expectLater(
      storage.persistSession('private-session'),
      throwsA(isA<AuthenticationFailure>().having((e) => e.kind, 'kind', AuthenticationFailureKind.storage)),
    );
    expect(storage.writeFailed, isTrue);
    backend.fail = false;
    await storage.setItem(key: 'verifier', value: 'private-verifier');
    expect(storage.writeFailed, isTrue);
    await storage.persistSession('new-session');
    expect(storage.writeFailed, isFalse);
    expect(await storage.accessToken(), 'new-session');
    backend.fail = true;
    await expectLater(storage.accessToken(), throwsA(isA<AuthenticationFailure>()));
  });
}

class _MemoryStorage implements SecureStorage {
  final values = <String, String>{};
  bool fail = false;
  Completer<void>? writeGate;

  @override
  Future<String?> read(String key) async {
    if (fail) throw StateError('test-only read failure');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    await writeGate?.future;
    if (fail) throw StateError('test-only write failure');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (fail) throw StateError('test-only delete failure');
    values.remove(key);
  }
}
