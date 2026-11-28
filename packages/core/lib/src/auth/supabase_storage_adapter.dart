import 'package:core/src/secure_storage/secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SDK interface mapping only. Encryption, ordering and failures belong to SecureStorage.
final class SupabaseStorageAdapter extends LocalStorage implements GotrueAsyncStorage {
  const SupabaseStorageAdapter({required this._namespace, required this._storage});
  final String _namespace;
  final SecureStorage _storage;
  String _key(String key) => '$_namespace:$key';

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;
  @override
  Future<String?> accessToken() => getItem(key: 'session');
  @override
  Future<void> persistSession(String value) => setItem(key: 'session', value: value);
  @override
  Future<void> removePersistedSession() => removeItem(key: 'session');
  @override
  Future<String?> getItem({required String key}) => _storage.read(_key(key));
  @override
  Future<void> setItem({required String key, required String value}) => _storage.write(_key(key), value);
  @override
  Future<void> removeItem({required String key}) => _storage.delete(_key(key));
}
