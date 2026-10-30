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
  Future<bool?> readBool({required String key}) async {
    return _preferences.getBool(key);
  }

  @override
  Future<int?> readInt({required String key}) async {
    return _preferences.getInt(key);
  }

  @override
  Future<String?> readString({required String key}) async {
    return _preferences.getString(key);
  }

  @override
  Future<void> writeBool({required String key, required bool value}) async {
    await _preferences.setBool(key, value);
  }

  @override
  Future<void> writeInt({required String key, required int value}) async {
    await _preferences.setInt(key, value);
  }

  @override
  Future<void> writeString({required String key, required String value}) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove({required String key}) async {
    await _preferences.remove(key);
  }
}
