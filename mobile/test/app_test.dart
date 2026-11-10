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
import 'package:home_feature/home_feature.dart';
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

  testWidgets('New Tricount opens a modal above Home and Join remains a placeholder', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      final home = find.bySemanticsIdentifier('home_title');
      final homeElement = tester.element(home);
      final navigation = find.byType(NavigationBar);
      expect(tester.widget<NavigationBar>(navigation).destinations, hasLength(2));
      await tester.tap(find.bySemanticsIdentifier('home_new_tricount'));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      final start = find.bySemanticsIdentifier('add_tricount_start');
      final join = find.bySemanticsIdentifier('add_tricount_join');
      expect(sheet, findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.byType(ListTile)), findsNWidgets(2));
      expect(start, findsOneWidget);
      expect(join, findsOneWidget);
      expect(GoRouterConfig.rootNavigatorKey.currentState?.canPop(), isTrue);
      expect(GoRouterConfig.homeNavigatorKey.currentState?.canPop(), isFalse);
      expect(find.bySemanticsIdentifier('tab_profile').hitTestable(), findsNothing);

      await tester.tap(join);
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.bySemanticsIdentifier('add_tricount_close'));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(tester.element(home), same(homeElement));
      await tester.tap(find.bySemanticsIdentifier('tab_profile'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('profile_page'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('tab_home'));
      await tester.pumpAndSettle();
      expect(tester.element(home), same(homeElement));
    });
  });

  testWidgets('the modal dismisses by Back, tapping outside, or dragging down', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      final action = find.bySemanticsIdentifier('home_new_tricount');
      final sheet = find.byType(BottomSheet);

      for (final dismiss in <Future<void> Function()>[
        () async {
          await tester.binding.handlePopRoute();
        },
        () => tester.tapAt(const Offset(8, 8)),
        () => tester.dragFrom(tester.getRect(sheet).topCenter + const Offset(0, 18), const Offset(0, 350)),
      ]) {
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        await dismiss();
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(action.hitTestable(), findsOneWidget);
      }
    });
  });

  testWidgets('the open modal translates both options when the locale changes', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('home_new_tricount'));
      await tester.pumpAndSettle();

      final heading = find.bySemanticsIdentifier('add_tricount_title');
      expect(find.text('Додати'), findsOneWidget);
      expect(find.text('Створити новий Tricount'), findsOneWidget);
      expect(find.text('Приєднатися до наявного Tricount'), findsOneWidget);
      await tester.element(heading).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Start New Tricount'), findsOneWidget);
      expect(find.text('Join Existing Tricount'), findsOneWidget);
    });
  });

  testWidgets('the form validates fields, preserves edits on save failure and confirms only a successful write', (
    tester,
  ) async {
    final repository = _GroupsRepository()
      ..failNextSave = true
      ..groups.add(const HomeGroup(id: 40, name: 'Earlier group', emoji: '⭐', currencyCode: 'EUR', participants: []));
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('home_new_tricount'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('add_tricount_start'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);

      final name = find.byKey(const ValueKey('group_name'));
      final create = find.text('Створити групу');
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Введіть назву групи'), findsOneWidget);
      expect(find.text('Виберіть валюту'), findsWidgets);
      expect(repository.attempts, 0);
      await tester.enterText(name, '  Mountain Trip  ');
      await tester.tap(find.byTooltip('Виберіть емоджі'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🏔️'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('group_currency')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('currency_search')), 'гривня');
      await tester.pumpAndSettle();
      await tester.tap(find.text('українська гривня'));
      await tester.pumpAndSettle();
      expect(find.text('українська гривня (UAH)'), findsOneWidget);

      final add = find.text('Додати учасника');
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Введіть ім’я учасника'), findsOneWidget);
      expect(repository.attempts, 0);
      final first = find.byType(TextFormField).at(1);
      await tester.enterText(first, 'First draft');
      await tester.enterText(first, '  Alex  ');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), 'Remove me');
      final remove = find.byTooltip('Видалити учасника').last;
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();

      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Не вдалося зберегти групу. Спробуйте ще раз.'), findsOneWidget);
      expect(find.text('  Mountain Trip  '), findsOneWidget);
      expect(find.text('  Alex  '), findsOneWidget);
      expect(find.text('Tricount створено'), findsNothing);
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Tricount створено'), findsOneWidget);
      expect(repository.groups.first.currencyCode, 'UAH');
      expect(repository.groups.first.emoji, '🏔️');
      expect(repository.groups.first.participants, ['Alex']);

      final heading = find.text('Tricount створено');
      expect(find.text('До групи'), findsOneWidget);
      await tester.element(heading).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Let's go!"));
      await tester.pumpAndSettle();
      final groupTitle = find.descendant(of: find.byType(AppBar), matching: find.text('Mountain Trip'));
      expect(groupTitle, findsOneWidget);
      expect(find.bySemanticsIdentifier('group_details'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.text('Tricount created'), findsNothing);
      expect(name, findsNothing);
      await tester.tap(find.text('Mountain Trip'));
      await tester.pumpAndSettle();
      expect(groupTitle, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Earlier group'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Earlier group')), findsOneWidget);
    }, repository: repository);
  });

  testWidgets('splash opens themed Home with an empty repository through the real DI and router', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.text('Tricount'), findsOneWidget);
      expect(find.text('У вас ще немає груп'), findsOneWidget);
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
  _GroupsRepository? repository,
}) async {
  final groups = repository ?? _GroupsRepository();
  try {
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    await GetIt.instance.unregister<HomeGroupsRepository>();
    DependencyProvider.registerLazySingleton<HomeGroupsRepository>(() => groups, dispose: (_) => groups.close());
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

class _GroupsRepository implements HomeGroupsRepository {
  final groups = <HomeGroup>[];
  final _updates = StreamController<Either<GroupsStorageFailure, List<HomeGroup>>>.broadcast();
  bool failNextSave = false;
  int attempts = 0;

  @override
  Stream<Either<GroupsStorageFailure, List<HomeGroup>>> watchGroups() async* {
    yield Right(List.of(groups));
    yield* _updates.stream;
  }

  @override
  Future<Either<GroupsStorageFailure, HomeGroup>> create(NewGroup group) async {
    attempts++;
    if (failNextSave) {
      failNextSave = false;
      return const Left(GroupsStorageFailure());
    }
    final saved = HomeGroup(
      id: groups.length + 1,
      name: group.name,
      emoji: group.emoji,
      currencyCode: group.currencyCode,
      participants: group.participants,
    );
    groups.insert(0, saved);
    _updates.add(Right(List.of(groups)));
    return Right(saved);
  }

  @override
  Future<Either<GroupsStorageFailure, HomeGroup?>> find(int id) async {
    for (final group in groups) {
      if (group.id == id) return Right(group);
    }
    return const Right(null);
  }

  Future<void> close() => _updates.close();
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
