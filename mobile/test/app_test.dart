import 'dart:convert';
import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/app.dart';
import 'package:mobile/main_common.dart' as bootstrap;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _TranslationsLoader translations;
  SharedPreferencesAsyncPlatform? previousPlatform;
  setUpAll(() async {
    final data = <String, Map<String, dynamic>>{};
    for (final language in ['uk', 'en']) {
      final json = await rootBundle.loadString('packages/common/lib/src/localization/langs/$language.json');
      data[language] = jsonDecode(json) as Map<String, dynamic>;
    }
    translations = _TranslationsLoader(data);
  });
  setUp(() async {
    previousPlatform = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({'locale': 'uk'});
    await EasyLocalization.ensureInitialized();
  });
  tearDown(() async {
    await DependencyProvider.reset();
    SharedPreferencesAsyncPlatform.instance = previousPlatform;
  });
  test('bootstrap awaits initialization before handing the widget to runApp', () async {
    final initializer = _GatedInitializer();
    var appStarted = false;
    final launch = bootstrap.run(
      environment: EnvironmentType.dev,
      initializer: initializer,
      appRunner: (_) => appStarted = true,
    );
    try {
      await initializer.started.future;
      expect(appStarted, isFalse);
    } finally {
      initializer.release.complete();
      await launch;
    }
    expect(appStarted, isTrue);
  });

  test('bootstrap leaves a recovery UI available after initialization fails', () async {
    Widget? root;
    await bootstrap.run(
      environment: EnvironmentType.dev,
      initializer: _FailingInitializer(),
      appRunner: (widget) => root = widget,
    );
    expect(root, isA<LocalizationsWrapper>());
    expect(DependencyProvider.get<StartupStatus>().isReady, isFalse);
  });

  testWidgets('splash opens the localized home screen through the real DI and router', (tester) async {
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
    expect(find.text('Спільні витрати'), findsOneWidget);
    final context = tester.element(find.bySemanticsIdentifier('home_title'));
    expect(Theme.of(context).colorScheme.primary, context.colors.primary);
    expect(tester.widget<Text>(find.text('Спільні витрати')).style, context.texts.title);
    await context.setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('Shared expenses'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await DependencyProvider.reset();
  });
  testWidgets('iOS also opens the localized home screen on a Flutter Material page', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
      await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.text('Спільні витрати'), findsOneWidget);
      final context = tester.element(find.bySemanticsIdentifier('home_title'));
      expect(ModalRoute.of(context)?.settings, isA<MaterialPage<void>>());
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await DependencyProvider.reset();
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
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
    await DependencyProvider.reset();
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

class _GatedInitializer implements ApplicationInitializer {
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> initialize() async {
    started.complete();
    await release.future;
  }
}

class _FailingInitializer implements ApplicationInitializer {
  @override
  Future<void> initialize() async => throw StateError('Initialization failed');
}
