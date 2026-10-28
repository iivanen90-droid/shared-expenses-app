import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _TranslationsLoader translations;
  setUpAll(() async {
    final data = <String, Map<String, dynamic>>{};
    for (final language in ['uk', 'en']) {
      final json = await rootBundle.loadString('packages/common/lib/src/localization/langs/$language.json');
      data[language] = jsonDecode(json) as Map<String, dynamic>;
    }
    translations = _TranslationsLoader(data);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({'locale': 'uk'});
    await EasyLocalization.ensureInitialized();
  });
  tearDown(DependencyProvider.reset);
  testWidgets('splash opens the localized home screen through the real DI and router', (tester) async {
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
    expect(find.text('Спільні витрати'), findsOneWidget);
    final context = tester.element(find.bySemanticsIdentifier('home_title'));
    await context.setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('Shared expenses'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('startup failure offers a semantic retry button and recovers', (tester) async {
    final status = StartupStatusImpl();
    final initializer = _RetryInitializer(status);
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev, initializer: initializer);
    // Use the same status observed by the startup source.
    initializer.status = DependencyProvider.get<StartupStatus>();
    await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
    await tester.pumpAndSettle();
    expect(DependencyProvider.get<StartupStatus>().isReady, isFalse);
    expect(find.bySemanticsIdentifier('splash_retry'), findsOneWidget);
    expect(initializer.attempts, 1);
    await tester.tap(find.bySemanticsIdentifier('splash_retry'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
    expect(initializer.attempts, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _TranslationsLoader extends AssetLoader {
  const _TranslationsLoader(this.translations);
  final Map<String, Map<String, dynamic>> translations;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) =>
      Future.value(translations[locale.languageCode] ?? const {});
}

class _RetryInitializer implements ApplicationInitializer {
  _RetryInitializer(this.status);
  StartupStatus status;
  int attempts = 0;
  @override
  Future<void> initialize() async {
    attempts++;
    if (attempts == 1) throw StateError("Initialization failed");
    status.markReady();
  }
}
