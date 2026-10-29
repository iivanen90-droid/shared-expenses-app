import 'dart:convert';

import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, Map<String, dynamic>> translations;

  setUpAll(() async {
    translations = {};
    for (final language in ['en', 'uk']) {
      final text = await rootBundle.loadString('lib/src/localization/langs/$language.json');
      translations[language] = jsonDecode(text) as Map<String, dynamic>;
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({'locale': 'uk'});
    await EasyLocalization.ensureInitialized();
  });

  test('registered translation assets have matching non-empty string keys', () {
    expect(translations['uk']?.keys.toSet(), translations['en']?.keys.toSet());
    for (final language in translations.values) {
      expect(language, isNotEmpty);
      expect(language.values.every((value) => value is String && value.isNotEmpty), isTrue);
    }
  });

  testWidgets('the wrapper uses package asset paths and restores Ukrainian', (tester) async {
    final loader = _TranslationsLoader(translations);
    await tester.pumpWidget(LocalizationsWrapper(assetLoader: loader, child: const _LocalizedTestApp()));
    await tester.pumpAndSettle();
    expect(find.text('Спільні витрати'), findsOneWidget);
    expect(find.text('Повторити'), findsOneWidget);
    expect(find.text('uk'), findsOneWidget);
    expect(loader.paths, everyElement('packages/common/lib/src/localization/langs'));
    expect(loader.languages.toSet(), containsAll(['uk', 'en']));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('switching locale rebuilds the UI and saves the selected language', (tester) async {
    await tester.pumpWidget(
      LocalizationsWrapper(assetLoader: _TranslationsLoader(translations), child: const _LocalizedTestApp()),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Спільні витрати'));
    await context.setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('Shared expenses'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('en'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('locale'), 'en');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a saved English locale is restored on launch', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      LocalizationsWrapper(assetLoader: _TranslationsLoader(translations), child: const _LocalizedTestApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shared expenses'), findsOneWidget);
    expect(find.text('en'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an unsupported saved locale falls back to English', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'de'});
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      LocalizationsWrapper(assetLoader: _TranslationsLoader(translations), child: const _LocalizedTestApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shared expenses'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('en'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a missing Ukrainian entry uses the English fallback without changing locale', (tester) async {
    final data = {
      'en': Map<String, dynamic>.of(translations['en'] ?? {}),
      'uk': Map<String, dynamic>.of(translations['uk'] ?? {})..remove(LocaleKeys.retry),
    };
    await tester.pumpWidget(
      LocalizationsWrapper(assetLoader: _TranslationsLoader(data), child: const _LocalizedTestApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Спільні витрати'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('uk'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _TranslationsLoader extends AssetLoader {
  _TranslationsLoader(this.translations);
  final Map<String, Map<String, dynamic>> translations;
  final paths = <String>[];
  final languages = <String>[];
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) {
    paths.add(path);
    languages.add(locale.languageCode);
    return Future.value(translations[locale.languageCode] ?? const {});
  }
}

class _LocalizedTestApp extends StatelessWidget {
  const _LocalizedTestApp();
  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: const Color(0xFF000000),
    locale: context.locale,
    supportedLocales: context.supportedLocales,
    localizationsDelegates: context.appLocalizationDelegates,
    textStyle: const TextStyle(fontSize: 14),
    builder: (_, _) => const _LocalizationProbe(),
  );
}

class _LocalizationProbe extends StatelessWidget {
  const _LocalizationProbe();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(LocaleKeys.appTitle.tr(context: context)),
      Text(LocaleKeys.retry.tr(context: context)),
      Text(Localizations.localeOf(context).languageCode),
    ],
  );
}
