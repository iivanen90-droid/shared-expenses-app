import 'package:core/src/preferences_storage/preferences_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { en, uk }

abstract interface class LanguagePreferences {
  Future<AppLanguage> load({AppLanguage fallback = AppLanguage.en});
  Future<void> save(AppLanguage language);
}

final class LanguagePreferencesImpl implements LanguagePreferences {
  const LanguagePreferencesImpl({required this._preferences});
  final PreferencesStorage _preferences;
  static const key = 'app.language';

  @override
  Future<AppLanguage> load({AppLanguage fallback = AppLanguage.en}) async {
    final stored = await _preferences.readString(key: key);
    // One-time migration from easy_localization's legacy preferences backend.
    final legacy = await SharedPreferences.getInstance();
    final code = stored ?? legacy.getString('locale');
    final language = AppLanguage.values.where((value) => value.name == code).firstOrNull ?? fallback;
    if (stored == null || stored != language.name) await save(language);
    // easy_localization 3.0.8 otherwise gives its cached legacy value precedence
    // over startLocale. Bootstrap runs ensureInitialized AFTER this migration.
    if (legacy.containsKey('locale') && !await legacy.remove('locale')) {
      throw StateError('Unable to migrate the legacy language preference');
    }
    return language;
  }

  @override
  Future<void> save(AppLanguage language) => _preferences.writeString(key: key, value: language.name);
}
