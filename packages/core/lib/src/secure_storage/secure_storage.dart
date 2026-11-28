import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureStorageFailure implements Exception {
  const SecureStorageFailure();
  @override
  String toString() => 'SecureStorageFailure';
}

/// Encrypted key/value storage with ordered writes and sanitized failures.
abstract interface class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// Waits for writes, including SDK fire-and-forget writes, and reports failed keys.
  Future<void> flush();
}

final class SecureStorageImpl implements SecureStorage {
  SecureStorageImpl({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );
  final FlutterSecureStorage _storage;
  Future<void> _pending = Future.value();
  final _failedKeys = <String>{};

  @override
  Future<String?> read(String key) async {
    await _pending;
    try {
      return await _storage.read(key: key);
    } on Object {
      throw const SecureStorageFailure();
    }
  }

  Future<void> _change(String key, Future<void> Function() operation) {
    final next = _pending.then((_) async {
      try {
        await operation();
        _failedKeys.remove(key);
      } on Object {
        _failedKeys.add(key);
        throw const SecureStorageFailure();
      }
    });
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  @override
  Future<void> write(String key, String value) => _change(key, () => _storage.write(key: key, value: value));
  @override
  Future<void> delete(String key) => _change(key, () => _storage.delete(key: key));
  @override
  Future<void> flush() async {
    await _pending;
    if (_failedKeys.isNotEmpty) throw const SecureStorageFailure();
  }
}
