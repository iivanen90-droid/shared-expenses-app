import 'dart:convert';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';
import 'package:home_feature/src/ui/home/home_analytics.dart';
import 'package:home_feature/src/ui/home/home_page.dart';
import 'package:home_feature/src/ui/home/state/home_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart';

class _Analytics extends Mock implements HomeAnalytics {}

class _Groups implements HomeGroupsInteractor {
  const _Groups(this.groups);

  final List<HomeGroup> groups;

  @override
  Stream<Either<GroupsStorageFailure, List<HomeGroup>>> watchGroups() => Stream.value(Right(groups));

  @override
  Future<Either<GroupsStorageFailure, HomeGroup>> create(NewGroup group) => throw UnimplementedError();
}

class _TranslationsLoader extends AssetLoader {
  const _TranslationsLoader(this.translations);

  final Map<String, Map<String, dynamic>> translations;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => translations[locale.languageCode] ?? {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _TranslationsLoader loader;
  setUpAll(() async {
    final data = <String, Map<String, dynamic>>{};
    for (final language in ['uk', 'en']) {
      final json = await rootBundle.loadString('packages/common/lib/src/localization/langs/$language.json');
      data[language] = jsonDecode(json) as Map<String, dynamic>;
    }
    loader = _TranslationsLoader(data);
  });
  test('opening Home loads the groups and emits the screen event', () async {
    const groups = [HomeGroup(id: 1, currencyCode: 'UAH', participants: [], name: 'Kyiv', emoji: '☕')];
    final analytics = _Analytics();
    final cubit = HomeCubit(analytics: analytics, interactor: const _Groups(groups));
    addTearDown(cubit.close);
    final loaded = cubit.stream.firstWhere((state) => state.status == HomeStatus.loaded);
    cubit.load();
    await loaded;
    expect(cubit.state.status, HomeStatus.loaded);
    expect(cubit.state.groups, groups);
    verify(analytics.onOpened).called(1);
  });

  testWidgets('Home shows the localized empty state and keeps creation available', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'uk'});
    await EasyLocalization.ensureInitialized();
    DependencyProvider.registerFactory<HomeCubit>(
      () => HomeCubit(analytics: _Analytics(), interactor: const _Groups([])),
    );
    try {
      final theme = AppTheme.main();
      await tester.pumpWidget(
        LocalizationsWrapper(
          assetLoader: loader,
          child: Builder(
            builder: (context) => AppThemeProvider(
              theme: theme,
              child: MaterialApp(
                theme: theme.material,
                locale: context.locale,
                localizationsDelegates: context.appLocalizationDelegates,
                supportedLocales: context.supportedLocales,
                home: const HomePage(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('У вас ще немає груп'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      final action = find.bySemanticsIdentifier('home_new_tricount');
      expect(action, findsOneWidget);
      final context = tester.element(action);
      await context.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('You don’t have any groups yet'), findsOneWidget);
      expect(find.text('New Tricount'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await DependencyProvider.reset();
    }
  });
}
