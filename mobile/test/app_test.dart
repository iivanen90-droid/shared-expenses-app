import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:router/router.dart';

import 'dart:convert';
import 'dart:async';

import 'package:flutter/services.dart' show rootBundle, SystemChannels, MethodCall;
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
  test('bootstrap awaits portrait lock before DI and initializer before runApp', () async {
    final orientationRequested = Completer<void>();
    final allowOrientation = Completer<void>();
    final initializer = _GatedInitializer();
    var appStarted = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          expect(call.arguments, ['DeviceOrientation.portraitUp']);
          orientationRequested.complete();
          await allowOrientation.future;
        }
        return null;
      },
    );
    final launch = bootstrap.run(
      environment: EnvironmentType.dev,
      initializer: initializer,
      appRunner: (_) => appStarted = true,
    );
    try {
      await orientationRequested.future;
      expect(DependencyProvider.isRegistered<ApplicationInitializer>(), isFalse);
      expect(initializer.started.isCompleted, isFalse);
      expect(appStarted, isFalse);
      allowOrientation.complete();
      await initializer.started.future;
      expect(DependencyProvider.isRegistered<ApplicationInitializer>(), isTrue);
      expect(appStarted, isFalse);
    } finally {
      if (!allowOrientation.isCompleted) allowOrientation.complete();
      initializer.release.complete();
      await launch;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
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

  testWidgets('splash waits for initialization and is removed when tabs open', (tester) async {
    final initializer = _BlockingInitializer();
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev, initializer: initializer);
    try {
      await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
      await tester.pump();
      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      initializer.release.complete();
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(GoRouterConfig.rootNavigatorKey.currentState?.canPop(), isFalse);
      expect(GoRouterConfig.homeNavigatorKey.currentState?.canPop(), isFalse);
      final didPop = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(didPop, isFalse);
      expect(find.byType(AppLoading), findsNothing);
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
    } finally {
      if (!initializer.release.isCompleted) initializer.release.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      await DependencyProvider.reset();
    }
  });

  testWidgets('bootstrap initializes once before splash and tabs on Android and iOS', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    try {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        final initializer = _CountingInitializer();
        Widget? root;
        await tester.runAsync(
          () => bootstrap.run(
            environment: EnvironmentType.dev,
            initializer: initializer,
            appRunner: (widget) => root = widget,
          ),
        );
        expect(initializer.calls, 1);
        expect(root, isA<LocalizationsWrapper>());
        await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
        await tester.pumpAndSettle();
        expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(initializer.calls, 1);
        final context = tester.element(find.bySemanticsIdentifier('home_title'));
        expect(Theme.of(context).colorScheme.primary, context.colors.primary);
        await context.setLocale(const Locale('en'));
        await tester.pumpAndSettle();
        expect(find.text('Shared expenses'), findsOneWidget);
        expect(initializer.calls, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await DependencyProvider.reset();
      }
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await DependencyProvider.reset();
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });
  testWidgets('both tabs preserve independent stacks including repeated tab selection', (tester) async {
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    try {
      await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('home_open_details'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_details'), findsOneWidget);
      expect(GoRouterConfig.homeNavigatorKey.currentState?.canPop(), isTrue);
      await tester.tap(find.bySemanticsIdentifier('tab_second'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('second_tab_title'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('second_open_details'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('second_details'), findsOneWidget);
      expect(GoRouterConfig.secondNavigatorKey.currentState?.canPop(), isTrue);
      await tester.tap(find.bySemanticsIdentifier('tab_home'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_details'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('tab_home'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_details'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('tab_second'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('second_details'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('second_tab_title'), findsOneWidget);
      expect(GoRouterConfig.rootNavigatorKey.currentState?.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await DependencyProvider.reset();
    }
  });

  testWidgets('language changes update both preserved tabs without resetting their stacks', (tester) async {
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    try {
      await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('home_open_details'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('tab_second'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('second_open_details'));
      await tester.pumpAndSettle();
      final context = tester.element(find.bySemanticsIdentifier('second_details'));
      await context.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Second tab'), findsOneWidget);
      expect(find.bySemanticsIdentifier('second_details'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('tab_home'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_details'), findsOneWidget);
      expect(find.text('Details'), findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await DependencyProvider.reset();
    }
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
  testWidgets('iOS opens the themed localized home screen on a Cupertino page', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
      await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.text('Спільні витрати'), findsOneWidget);
      final context = tester.element(find.bySemanticsIdentifier('home_title'));
      expect(ModalRoute.of(context)?.settings, isA<CupertinoPage<void>>());
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

class _BlockingInitializer implements ApplicationInitializer {
  final release = Completer<void>();
  @override
  Future<void> initialize() async {
    await release.future;
    DependencyProvider.get<StartupStatus>().markReady();
  }
}

class _CountingInitializer implements ApplicationInitializer {
  int calls = 0;
  @override
  Future<void> initialize() async {
    calls++;
    DependencyProvider.get<StartupStatus>().markReady();
  }
}
