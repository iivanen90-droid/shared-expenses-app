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
import 'package:get_it/get_it.dart';

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
  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = previousPlatform;
  });
  testWidgets('bootstrap requests portrait before DI and prepares the first frame', (tester) async {
    var orientationRequests = 0;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    try {
      await tester.runAsync(() async {
        messenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            expect(call.arguments, ['DeviceOrientation.portraitUp']);
            expect(DependencyProvider.isRegistered<ApplicationInitializer>(), isFalse);
            orientationRequests++;
          }
          return null;
        });
        await bootstrap.run(environment: EnvironmentType.dev);
      });
      expect(orientationRequests, 1);
      expect(DependencyProvider.get<StartupStatus>().isReady, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(LocalizationsWrapper), findsOneWidget);
    } finally {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      await _disposeApp(tester);
    }
  });

  testWidgets('splash waits for initialization and is removed when tabs open', (tester) async {
    final initializer = _BlockingInitializer();
    await _withApp(tester, translations, () async {
      try {
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
      }
    }, initializer: initializer);
  });

  testWidgets('bootstrap prepares the application root on Android and iOS', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    try {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        try {
          await tester.runAsync(() => bootstrap.run(environment: EnvironmentType.dev));
          expect(DependencyProvider.get<StartupStatus>().isReady, isTrue);
          await tester.pumpAndSettle();
          expect(find.byType(LocalizationsWrapper), findsOneWidget);
        } finally {
          await _disposeApp(tester);
        }
      }
    } finally {
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });

  testWidgets('Home keeps the New Tricount page open after switching tabs and reselecting Home', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      final navigation = find.byType(NavigationBar);
      expect(tester.widget<NavigationBar>(navigation).destinations, hasLength(2));
      await tester.tap(find.bySemanticsIdentifier('home_new_tricount'));
      await tester.pumpAndSettle();
      final placeholder = find.bySemanticsIdentifier('new_tricount_title');
      expect(placeholder, findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(GoRouterConfig.homeNavigatorKey.currentState?.canPop(), isTrue);
      await tester.tap(find.bySemanticsIdentifier('tab_profile'));
      await tester.pumpAndSettle();
      final profile = find.bySemanticsIdentifier('profile_page');
      final profileElement = tester.element(profile);
      expect(placeholder, findsNothing);
      expect(GoRouterConfig.profileNavigatorKey.currentState?.canPop(), isFalse);
      await tester.tap(find.bySemanticsIdentifier('tab_home'));
      await tester.pumpAndSettle();
      expect(placeholder, findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('tab_home'));
      await tester.pumpAndSettle();
      expect(placeholder, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('tab_profile'));
      await tester.pumpAndSettle();
      expect(tester.element(profile), same(profileElement));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('language changes update both tab labels and the open New Tricount page', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('home_new_tricount'));
      await tester.pumpAndSettle();
      final placeholder = find.bySemanticsIdentifier('new_tricount_title');
      final context = tester.element(placeholder);
      expect(find.text('Новий Tricount'), findsOneWidget);
      expect(find.text('Головна'), findsOneWidget);
      expect(find.text('Профіль'), findsOneWidget);
      await context.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('New Tricount'), findsOneWidget);
      expect(tester.element(placeholder), same(context));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('splash opens themed Home with demo groups through the real DI and router', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.text('Tricount'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
      expect(find.text('Kyiv'), findsOneWidget);
      expect(find.text('Carpathians'), findsOneWidget);
      expect(find.text('У вас ще немає груп'), findsNothing);
      expect(find.text('Новий Tricount'), findsOneWidget);
      final context = tester.element(find.bySemanticsIdentifier('home_title'));
      expect(Theme.of(context).colorScheme.primary, context.colors.primary);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('iOS opens the themed localized home screen on a Cupertino page', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _withApp(tester, translations, () async {
        await tester.pumpAndSettle();
        expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
        expect(find.text('Tricount'), findsOneWidget);
        final context = tester.element(find.bySemanticsIdentifier('home_title'));
        expect(ModalRoute.of(context)?.settings, isA<CupertinoPage<void>>());
        expect(tester.takeException(), isNull);
      });
    } finally {
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });

  testWidgets('startup failure offers a semantic retry button and recovers', (tester) async {
    final initializer = _RetryInitializer();
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      expect(DependencyProvider.get<StartupStatus>().isReady, isFalse);
      expect(find.bySemanticsIdentifier('splash_retry'), findsOneWidget);
      expect(initializer.attempts, 1);
      await tester.tap(find.bySemanticsIdentifier('splash_retry'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(initializer.attempts, 2);
      expect(tester.takeException(), isNull);
    }, initializer: initializer);
  });
}

Future<void> _withApp(
  WidgetTester tester,
  AssetLoader translations,
  Future<void> Function() testBody, {
  ApplicationInitializer? initializer,
}) async {
  try {
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    if (initializer != null) {
      await GetIt.instance.unregister<ApplicationInitializer>();
      DependencyProvider.registerLazySingleton<ApplicationInitializer>(() => initializer);
    }
    await tester.pumpWidget(LocalizationsWrapper(assetLoader: translations, child: const App()));
    await testBody();
  } finally {
    await _disposeApp(tester);
  }
}

Future<void> _disposeApp(WidgetTester tester) async {
  try {
    await tester.pumpWidget(const SizedBox.shrink());
  } finally {
    await DependencyProvider.reset();
  }
}

class _TranslationsLoader extends AssetLoader {
  const _TranslationsLoader(this.translations);
  final Map<String, Map<String, dynamic>> translations;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) =>
      Future.value(translations[locale.languageCode] ?? const {});
}

class _RetryInitializer implements ApplicationInitializer {
  int attempts = 0;
  @override
  Future<void> initialize() async {
    attempts++;
    if (attempts == 1) throw StateError("Initialization failed");
    DependencyProvider.get<StartupStatus>().markReady();
  }
}

class _BlockingInitializer implements ApplicationInitializer {
  final release = Completer<void>();
  @override
  Future<void> initialize() async {
    await release.future;
    DependencyProvider.get<StartupStatus>().markReady();
  }
}
