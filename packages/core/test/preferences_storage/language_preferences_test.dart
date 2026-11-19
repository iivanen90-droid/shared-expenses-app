import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Preferences storage;
  late LanguagePreferencesImpl languages;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = _Preferences();
    languages = LanguagePreferencesImpl(preferences: storage);
  });
  test('save is restored by a new service through PreferencesStorage', () async {
    await languages.save(AppLanguage.uk);
    expect(await LanguagePreferencesImpl(preferences: storage).load(), AppLanguage.uk);
    expect((await SharedPreferences.getInstance()).getString('locale'), isNull);
  });
  test('migrates easy_localization once and clears its second source', () async {
    SharedPreferences.setMockInitialValues({'locale': 'uk'});
    expect(await languages.load(), AppLanguage.uk);
    expect(storage.value, 'uk');
    expect((await SharedPreferences.getInstance()).getString('locale'), isNull);
  });
  test('canonical choice wins over a contradictory legacy choice', () async {
    storage.value = 'en';
    SharedPreferences.setMockInitialValues({'locale': 'uk'});
    expect(await languages.load(), AppLanguage.en);
    expect((await SharedPreferences.getInstance()).getString('locale'), isNull);
  });
  test('invalid or absent choice uses the supported device fallback', () async {
    storage.value = 'de';
    expect(await languages.load(fallback: AppLanguage.uk), AppLanguage.uk);
    expect(storage.value, 'uk');
  });
  test('failed migration preserves the legacy choice for a later retry', () async {
    SharedPreferences.setMockInitialValues({'locale': 'uk'});
    storage.fail = true;
    await expectLater(languages.load(), throwsStateError);
    expect((await SharedPreferences.getInstance()).getString('locale'), 'uk');
    storage.fail = false;
    expect(await languages.load(), AppLanguage.uk);
  });
  test('failed save does not replace the previously selected language', () async {
    await languages.save(AppLanguage.en);
    storage.fail = true;
    await expectLater(languages.save(AppLanguage.uk), throwsStateError);
    expect(storage.value, 'en');
  });
}

class _Preferences implements PreferencesStorage {
  String? value;
  bool fail = false;
  @override
  Future<String?> readString({required String key}) async => value;
  @override
  Future<void> writeString({required String key, required String value}) async {
    if (fail) throw StateError('Test preferences unavailable');
    this.value = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
