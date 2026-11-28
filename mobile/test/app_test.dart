import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:router/router.dart';

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show CachingAssetBundle, rootBundle, SystemChannels, MethodCall;
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

late String _currencyCatalog;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _TranslationsLoader translations;
  SharedPreferencesAsyncPlatform? previousPlatform;
  setUpAll(() async {
    _currencyCatalog = await rootBundle.loadString('packages/home_feature/assets/currencies.json');
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
    SharedPreferences.setMockInitialValues({});
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
        SharedPreferences.setMockInitialValues({'locale': 'uk'});
        await SharedPreferencesAsync().setString('app.language', 'en');
        await bootstrap.run(environment: EnvironmentType.dev);
      });
      expect(orientationRequests, 1);
      expect(DependencyProvider.get<StartupStatus>().isReady, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(LocalizationsWrapper), findsOneWidget);
      expect(tester.widget<LocalizationsWrapper>(find.byType(LocalizationsWrapper)).initialLocale, const Locale('en'));
      expect((await SharedPreferences.getInstance()).getString('locale'), isNull);
    } finally {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      await _disposeBootstrapApp(tester);
    }
  });

  testWidgets('splash waits for initialization and is removed when tabs open', (tester) async {
    final initializer = _BlockingInitializer();
    await _withApp(tester, translations, () async {
      try {
        await tester.pump();
        expect(find.bySemanticsIdentifier('splash_brand'), findsOneWidget);
        expect(find.text('Спільні витрати'), findsOneWidget);
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
        expect(find.bySemanticsIdentifier('splash_brand'), findsNothing);
        expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      } finally {
        if (!initializer.release.isCompleted) initializer.release.complete();
      }
    }, initializer: initializer);
  });

  testWidgets('splash remains readable in both languages with large text on a small screen and supports retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final initializer = _RetryInitializer();
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      expect(find.text('Спільні витрати'), findsOneWidget);
      expect(find.text('Не вдалося запустити застосунок'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.element(find.bySemanticsIdentifier('splash_brand')).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Shared expenses'), findsOneWidget);
      expect(find.text('Unable to start the app'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final retry = find.bySemanticsIdentifier('splash_retry');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(initializer.attempts, 2);
      expect(find.bySemanticsIdentifier('splash_brand'), findsNothing);
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(GoRouterConfig.rootNavigatorKey.currentState?.canPop(), isFalse);
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
          await _disposeBootstrapApp(tester);
        }
      }
    } finally {
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });

  testWidgets('New group opens a modal above Home with both actions', (tester) async {
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

  testWidgets('Join opens a localized screen and returns to the same Home without the sheet', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      final home = find.bySemanticsIdentifier('home_title');
      final homeElement = tester.element(home);

      Future<void> openJoin() async {
        await tester.tap(find.bySemanticsIdentifier('home_new_tricount'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsIdentifier('add_tricount_join'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(NavigationBar).hitTestable(), findsNothing);
      }

      await openJoin();
      final linkField = find.byType(TextField);
      expect(find.text('Приєднатися до групи'), findsOneWidget);
      expect(find.text('Вставте посилання тут'), findsOneWidget);
      final joinButton = find.widgetWithText(FilledButton, 'Приєднатися');
      expect(tester.widget<FilledButton>(joinButton).onPressed, isNull);
      await tester.enterText(linkField, '   ');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(joinButton).onPressed, isNull);
      await tester.enterText(linkField, 'invite text');
      await tester.pumpAndSettle();
      await tester.tap(joinButton);
      await tester.pumpAndSettle();
      expect(find.text('Приєднання буде доступне пізніше'), findsOneWidget);
      expect(find.text('invite text'), findsOneWidget);

      await tester.element(linkField).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Join a group'), findsOneWidget);
      expect(find.text('Paste your link here'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Join'), findsOneWidget);
      expect(find.text('Joining will be available later'), findsOneWidget);

      await tester.enterText(linkField, '');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Join')).onPressed, isNull);
      expect(find.text('Joining will be available later'), findsNothing);

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(tester.element(home), same(homeElement));
      expect(find.byType(BottomSheet), findsNothing);
      expect(linkField, findsNothing);

      await openJoin();
      expect(find.text('invite text'), findsNothing);
      expect(find.text('Joining will be available later'), findsNothing);
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(tester.element(home), same(homeElement));
      expect(linkField, findsNothing);
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
      expect(find.text('Створити нову групу'), findsOneWidget);
      expect(find.text('Приєднатися до наявної групи'), findsOneWidget);
      await tester.element(heading).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Start a new group'), findsOneWidget);
      expect(find.text('Join an existing group'), findsOneWidget);
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
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.text('😀').hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('group_currency')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
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
      await tester.enterText(first, 'Remove me');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '  Alex  ');
      final remove = find.byTooltip('Видалити учасника').first;
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();

      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Не вдалося зберегти групу. Спробуйте ще раз.'), findsOneWidget);
      expect(find.text('  Mountain Trip  '), findsOneWidget);
      expect(find.text('  Alex  '), findsOneWidget);
      expect(find.text('Групу створено'), findsNothing);
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Групу створено'), findsOneWidget);
      expect(repository.groups.first.currencyCode, 'UAH');
      expect(repository.groups.first.emoji, '😀');
      expect(repository.groups.first.participants, ['Alex']);

      final heading = find.text('Групу створено');
      expect(find.text('До групи'), findsOneWidget);
      await tester.element(heading).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Group created'), findsOneWidget);
      await tester.tap(find.text("Let's go!"));
      await tester.pumpAndSettle();
      final groupTitle = find.descendant(of: find.byType(AppBar), matching: find.text('Mountain Trip'));
      expect(groupTitle, findsOneWidget);
      expect(find.bySemanticsIdentifier('group_details'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.text('Group created'), findsNothing);
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

  testWidgets('repeated submits reveal a blank participant above the viewport without saving', (tester) async {
    final repository = _GroupsRepository();
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('home_new_tricount'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('add_tricount_start'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('group_name')), 'Long trip');
      await tester.tap(find.byKey(const ValueKey('group_currency')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('currency_search')), 'USD');
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(ListTile), matching: find.text('USD')));
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(of: find.byKey(const ValueKey('group_form_scroll')), matching: find.byType(Scrollable))
          .first;
      final add = find.text('Додати учасника');
      for (var i = 0; i < 18; i++) {
        await tester.scrollUntilVisible(add, 100, scrollable: scrollable);
        await tester.tap(add);
        await tester.pumpAndSettle();
        if (i > 0) {
          await tester.scrollUntilVisible(add, 100, scrollable: scrollable);
          await tester.enterText(find.byType(TextFormField).last, 'Person $i');
          await tester.pumpAndSettle();
        }
      }

      final create = find.text('Створити групу');
      final participantError = find.text('Введіть ім’я учасника');
      expect(participantError, findsNothing);

      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.scrollUntilVisible(create, 100, scrollable: scrollable);
        expect(participantError.hitTestable(), findsNothing);
        await tester.tap(create);
        await tester.pumpAndSettle();
        expect(repository.attempts, 0);
        expect(participantError.hitTestable(), findsOneWidget);
      }
    }, repository: repository);
  });

  testWidgets('splash opens themed Home with an empty repository through the real DI and router', (tester) async {
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('home_title'), findsOneWidget);
      expect(find.text('Tricount'), findsOneWidget);
      expect(find.text('У вас ще немає груп'), findsOneWidget);
      expect(find.text('Нова група'), findsOneWidget);
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

  testWidgets('unconfigured authentication returns to Home with the same local group', (tester) async {
    final repository = _GroupsRepository();
    final saved = await repository.create((
      name: 'Test trip',
      emoji: '💸',
      currencyCode: 'UAH',
      participants: ['Participant'],
    ));
    final group = saved.getOrElse((_) => throw StateError('Test group setup failed'));
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      expect(find.text(group.name), findsOneWidget);
      final homeElement = tester.element(find.bySemanticsIdentifier('home_title'));
      await _openAccount(tester);
      expect(find.text('Вхід'), findsOneWidget);
      expect(find.bySemanticsIdentifier('auth_google'), findsNothing);
      expect(find.text('Вхід зараз недоступний. Ви можете користуватися локальними групами.'), findsOneWidget);
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('tab_home').hitTestable());
      await tester.pumpAndSettle();
      expect(tester.element(find.bySemanticsIdentifier('home_title')), same(homeElement));
      expect(find.text(group.name), findsOneWidget);
      expect(repository.groups.single, same(group));
    }, repository: repository);
  });

  testWidgets('Google sign-in can be cancelled and started again', (tester) async {
    final auth = _AuthService();
    addTearDown(auth.updates.close);
    await _withApp(tester, translations, () async {
      await _openAccount(tester);
      await tester.tap(find.bySemanticsIdentifier('auth_google'));
      await tester.pump();
      expect(auth.launches, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Скасувати вхід'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 1);
      expect(find.text('Вхід скасовано.'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('auth_google'));
      await tester.pump();
      expect(auth.launches, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    }, authService: auth);
  });

  testWidgets('Google completion returns to Home and Profile owns localized sign-out', (tester) async {
    final auth = _AuthService();
    addTearDown(auth.updates.close);
    final repository = _GroupsRepository();
    await repository.create((name: 'Saved trip', emoji: '💸', currencyCode: 'UAH', participants: ['Participant']));
    await _withApp(
      tester,
      translations,
      () async {
        await _openAccount(tester);
        await tester.tap(find.bySemanticsIdentifier('auth_google'));
        await tester.pump();
        auth.emitSession(AuthenticationStatus.signedIn);
        await tester.pumpAndSettle();
        expect(find.text('Saved trip'), findsOneWidget);
        expect(find.bySemanticsIdentifier('auth_google'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.tap(find.bySemanticsIdentifier('tab_profile').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('Вийти'), findsOneWidget);
        await tester.element(find.bySemanticsIdentifier('profile_logout')).setLocale(const Locale('en'));
        await tester.pumpAndSettle();
        expect(find.text('Sign out'), findsOneWidget);
        await tester.tap(find.bySemanticsIdentifier('profile_logout'));
        await tester.pumpAndSettle();
        expect(auth.signOuts, 1);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(await tester.binding.handlePopRoute(), isFalse);
        await tester.pumpAndSettle();
        expect(repository.groups.single.name, 'Saved trip');
      },
      authService: auth,
      repository: repository,
    );
  });

  testWidgets('storage failure keeps the active account recoverable from Profile', (tester) async {
    final auth = _AuthService();
    addTearDown(auth.updates.close);
    await _withApp(tester, translations, () async {
      await _openAccount(tester);
      await tester.tap(find.bySemanticsIdentifier('auth_google'));
      await tester.pump();
      auth.emitSession(
        AuthenticationStatus.signedIn,
        failure: const AuthenticationFailure(AuthenticationFailureKind.storage),
      );
      await tester.pumpAndSettle();
      expect(find.text('Не вдалося безпечно зберегти або видалити сесію. Спробуйте ще раз.'), findsOneWidget);
      expect(find.bySemanticsIdentifier('auth_google'), findsNothing);
      await tester.tap(find.text('Обліковий запис'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('profile_logout'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('profile_logout'));
      await tester.pumpAndSettle();
      expect(find.text('Продовжити з Google'), findsOneWidget);
    }, authService: auth);
  });

  testWidgets('failed Profile logout stays retryable and does not navigate early', (tester) async {
    final auth = _AuthService(initialStatus: AuthenticationStatus.signedIn)..failSignOut = true;
    addTearDown(auth.updates.close);
    await _withApp(tester, translations, () async {
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('tab_profile').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('profile_logout'));
      await tester.pumpAndSettle();
      expect(find.text('Не вдалося вийти. Спробуйте ще раз.'), findsOneWidget);
      expect(find.bySemanticsIdentifier('profile_logout'), findsOneWidget);
      expect(find.bySemanticsIdentifier('auth_google'), findsNothing);
      auth.failSignOut = false;
      await tester.tap(find.bySemanticsIdentifier('profile_logout'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 2);
      expect(find.text('Продовжити з Google'), findsOneWidget);
    }, authService: auth);
  });

  testWidgets('closing a pending auth page cancels its attempt and permits reopening', (tester) async {
    final auth = _AuthService();
    addTearDown(auth.updates.close);
    await _withApp(tester, translations, () async {
      await _openAccount(tester);
      await tester.tap(find.bySemanticsIdentifier('auth_google'));
      await tester.pump();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(auth.signOuts, 1);
      await tester.tap(find.bySemanticsIdentifier('profile_account'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('auth_google'));
      await tester.pump();
      expect(auth.launches, 2);
      await tester.tap(find.text('Скасувати вхід'));
      await tester.pumpAndSettle();
    }, authService: auth);
  });

  testWidgets(
    'Profile shows identity, applies and persists language, then clears navigation only after successful logout',
    (tester) async {
      final auth = _AuthService()
        ..session = AuthenticationStatus.signedIn
        ..profile = const AuthenticationProfile(name: 'Test Person', email: 'test@example.invalid')
        ..failSignOut = true;
      final groups = _GroupsRepository()
        ..groups.add(const HomeGroup(id: 1, name: 'Local group', emoji: '🌍', currencyCode: 'UAH', participants: []));
      try {
        await _withApp(
          tester,
          translations,
          () async {
            await tester.pumpAndSettle();
            await tester.tap(find.bySemanticsIdentifier('tab_profile'));
            await tester.pumpAndSettle();
            expect(find.text('Test Person'), findsOneWidget);
            expect(find.text('test@example.invalid'), findsOneWidget);
            await tester.tap(find.bySemanticsIdentifier('profile_language'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('English').last);
            await tester.pumpAndSettle();
            expect(find.text('Language'), findsOneWidget);
            expect(find.text('Home'), findsOneWidget);
            expect(await DependencyProvider.get<PreferencesStorage>().readString(key: 'app.language'), 'en');
            await tester.tap(find.bySemanticsIdentifier('profile_logout'));
            await tester.pumpAndSettle();
            expect(find.text('Unable to sign out. Please try again.'), findsOneWidget);
            expect(find.text('Test Person'), findsOneWidget);
            auth.failSignOut = false;
            await tester.tap(find.bySemanticsIdentifier('profile_logout'));
            await tester.pumpAndSettle();
            expect(find.text('Continue with Google'), findsOneWidget);
            expect(find.byType(NavigationBar), findsNothing);
            expect(find.text('Test Person'), findsNothing);
            expect(GoRouterConfig.rootNavigatorKey.currentState?.canPop(), isFalse);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(find.bySemanticsIdentifier('profile_page'), findsNothing);
            expect(groups.groups.single.name, 'Local group');
            expect(await DependencyProvider.get<PreferencesStorage>().readString(key: 'app.language'), 'en');
          },
          authService: auth,
          repository: groups,
        );
      } finally {
        await auth.updates.close();
      }
    },
  );

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

Future<void> _openAccount(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsIdentifier('tab_profile').hitTestable());
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsIdentifier('profile_account'));
  await tester.pumpAndSettle();
}

Future<void> _disposeBootstrapApp(WidgetTester tester) async {
  try {
    await tester.pumpWidget(const SizedBox.shrink());
  } finally {
    // Bootstrap creates its services in runAsync; dispose them in that zone too.
    await tester.runAsync(DependencyProvider.reset);
  }
}

Future<void> _withApp(
  WidgetTester tester,
  AssetLoader translations,
  Future<void> Function() testBody, {
  ApplicationInitializer? initializer,
  _GroupsRepository? repository,
  AuthService? authService,
}) async {
  final groups = repository ?? _GroupsRepository();
  try {
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    if (authService != null) {
      await GetIt.instance.unregister<AuthService>();
      DependencyProvider.registerLazySingleton<AuthService>(() => authService);
      await GetIt.instance.unregister<AuthSessionSource>();
      DependencyProvider.registerLazySingleton<AuthSessionSource>(() => authService as AuthSessionSource);
    }
    await GetIt.instance.unregister<HomeGroupsRepository>();
    DependencyProvider.registerLazySingleton<HomeGroupsRepository>(() => groups, dispose: (_) => groups.close());
    if (initializer != null) {
      await GetIt.instance.unregister<ApplicationInitializer>();
      DependencyProvider.registerLazySingleton<ApplicationInitializer>(() => initializer);
    }
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: LocalizationsWrapper(initialLocale: const Locale('uk'), assetLoader: translations, child: const App()),
      ),
    );
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
  Future<Either<GroupsStorageFailure, HomeGroup?>> getGroupById(int id) async {
    for (final group in groups) {
      if (group.id == id) return Right(group);
    }
    return const Right(null);
  }

  Future<void> close() => _updates.close();
}

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) => key == 'packages/home_feature/assets/currencies.json'
      ? Future.value(_currencyCatalog)
      : rootBundle.loadString(key, cache: cache);
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

class _AuthService implements AuthService, AuthSessionSource {
  _AuthService({AuthenticationStatus initialStatus = AuthenticationStatus.signedOut}) : session = initialStatus;
  AuthenticationStatus session;
  AuthenticationProfile? profile;
  AuthenticationFailure? _failure;
  @override
  AuthenticationProfile? get currentProfile => session == AuthenticationStatus.signedIn ? profile : null;
  @override
  AuthenticationSnapshot get current => (session: session, failure: _failure);
  final updates = StreamController<AuthenticationSnapshot>.broadcast();
  int launches = 0;
  int signOuts = 0;
  bool failSignOut = false;
  @override
  Future<void> initialize() async {}
  void emitSession(AuthenticationStatus value, {AuthenticationFailure? failure}) {
    session = value;
    _failure = failure;
    if (value != AuthenticationStatus.signedIn) profile = null;
    updates.add(current);
  }

  @override
  Stream<AuthenticationSnapshot> watchChanges() => updates.stream;
  @override
  Future<Either<AuthenticationFailure, Unit>> launchSignIn({required AuthSource source}) async {
    launches++;
    _failure = null;
    return const Right(unit);
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() async {
    signOuts++;
    if (failSignOut) {
      const failure = AuthenticationFailure(AuthenticationFailureKind.storage);
      _failure = failure;
      updates.add(current);
      return const Left(failure);
    }
    emitSession(AuthenticationStatus.signedOut);
    return const Right(unit);
  }
}
