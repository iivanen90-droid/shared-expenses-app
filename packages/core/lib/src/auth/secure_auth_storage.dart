import 'package:core/src/auth/auth_service.dart';
import 'package:core/src/secure_storage/secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serializes writes so a token refresh cannot restore a session after sign-out.
final class SecureAuthStorage extends LocalStorage implements GotrueAsyncStorage {
  SecureAuthStorage({required this._namespace, SecureStorage? storage}) : _storage = storage ?? SecureStorageImpl();

  final String _namespace;
  final SecureStorage _storage;
  Future<void> _pending = Future.value();
  final _failedKeys = <String>{};

  Future<void> get pending => _pending;
  bool get writeFailed => _failedKeys.isNotEmpty;

  String _key(String key) => '$_namespace:$key';

  Future<void> _write(String key, Future<void> Function() operation) {
    final next = _pending.then((_) async {
      try {
        await operation();
        _failedKeys.remove(key);
      } on Object {
        _failedKeys.add(key);
        throw const AuthenticationFailure(AuthenticationFailureKind.storage);
      }
    });
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() => getItem(key: 'session');

  @override
  Future<void> persistSession(String persistSessionString) => setItem(key: 'session', value: persistSessionString);

  @override
  Future<void> removePersistedSession() => removeItem(key: 'session');

  @override
  Future<String?> getItem({required String key}) async {
    await _pending;
    try {
      return await _storage.read(_key(key));
    } on Object {
      throw const AuthenticationFailure(AuthenticationFailureKind.storage);
    }
  }

  @override
  Future<void> setItem({required String key, required String value}) =>
      _write(key, () => _storage.write(_key(key), value));

  @override
  Future<void> removeItem({required String key}) => _write(key, () => _storage.delete(_key(key)));
}
