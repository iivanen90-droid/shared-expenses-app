import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesStorage {
  Future<bool?> readBool({required String key});
  Future<int?> readInt({required String key});
  Future<String?> readString({required String key});
  Future<void> writeBool({required String key, required bool value});
  Future<void> writeInt({required String key, required int value});
  Future<void> writeString({required String key, required String value});
  Future<void> remove({required String key});
}

final class PreferencesStorageImpl implements PreferencesStorage {
  PreferencesStorageImpl({required this._preferences});
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool?> readBool({required String key}) => _preferences.getBool(key);
  @override
  Future<int?> readInt({required String key}) => _preferences.getInt(key);
  @override
  Future<String?> readString({required String key}) => _preferences.getString(key);
  @override
  Future<void> writeBool({required String key, required bool value}) => _preferences.setBool(key, value);
  @override
  Future<void> writeInt({required String key, required int value}) => _preferences.setInt(key, value);
  @override
  Future<void> writeString({required String key, required String value}) => _preferences.setString(key, value);
  @override
  Future<void> remove({required String key}) => _preferences.remove(key);
}
