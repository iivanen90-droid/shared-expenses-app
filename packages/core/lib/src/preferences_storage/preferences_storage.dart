import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesStorage {
  Future<String?> readString({required String key});
  Future<void> writeString({required String key, required String value});
}

final class PreferencesStorageImpl implements PreferencesStorage {
  PreferencesStorageImpl({required this._preferences});
  final SharedPreferencesAsync _preferences;
  @override
  Future<String?> readString({required String key}) => _preferences.getString(key);
  @override
  Future<void> writeString({required String key, required String value}) => _preferences.setString(key, value);
}
