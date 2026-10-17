# Inspiro architecture: reference for the test app

This document describes how our Flutter app Inspiro is built. The test app must reproduce **the same structure**,
even where it feels heavy for a small project. That is the main requirement of the task.

> **Agent:** put this file in the root of the new repository as `CLAUDE.md` (or reference it from `CLAUDE.md`).
> The architecture decisions table below and sections 1–9 are mandatory. Use exactly the listed package for each
> concern; don't substitute an alternative (Riverpod, Provider, auto_route, intl ARB, injectable, Hive…) without
> explicit approval.

## Architecture decisions at a glance

| Concern | Decision | Package(s) | Where it lives |
|---|---|---|---|
| Project layout | Dart workspace monorepo: shared packages + one package per feature | Dart `workspace:` / `resolution: workspace`, FVM | root `pubspec.yaml` |
| Feature architecture | Clean architecture per feature: `data → domain → ui`, "interface + Impl" for every class | — | `features/<name>_feature/lib/src/{data,domain,ui}` |
| State management | Cubit only (no Bloc events), base class `SafeCubitWrapper`, single freezed state with a status enum | `flutter_bloc` | `ui/<screen>/state/` |
| Dependency injection | Service locator behind a static `DependencyProvider` facade; three resolvers per feature (data/domain/ui) | `get_it` | `core/lib/src/di/`, wired in `common/lib/src/di/` |
| Routing | Typed declarative routes, all in one package; `StatefulShellRoute` for tabs; splash as entry | `go_router` + `go_router_builder` | `packages/router` |
| Localization | JSON translations + generated `LocaleKeys`, `LocaleKeys.x.tr()` everywhere | `easy_localization` (+ `intl`) | `common/lib/src/localization/langs/` |
| Models / immutability | freezed for states, entities, UI models, unions | `freezed` + `freezed_annotation` | next to their layer |
| JSON / DTOs | json_serializable for API DTOs only, mappers DTO → entity | `json_serializable` + `json_annotation` | `data/dto/`, `data/repository/mapper/` |
| Error handling | `Future<Either<Failure, T>>`, exceptions caught in data/domain and mapped to `Failure` | `fpdart` | `core/lib/src/domain/failure/` |
| Networking | One `ApiClient` wrapper returning `Either<ApiError, T>` | `dio` | `core/lib/src/api_client/` |
| Local storage | Key-value through a storage source wrapper; DB for structured data | `shared_preferences`; `objectbox` | `core/lib/src/preferences_storage/` |
| Theme / design system | `AppThemeProvider` + `context.colors / texts / icons`, no hardcoded styles | — (own `ui_kit`) | `packages/ui_kit` |
| Material / Cupertino | Imported from pub packages, never from the Flutter SDK | `material_ui`, `cupertino_ui` | every package that renders UI |
| Assets | Generated typed accessors | `flutter_gen_runner`, `flutter_svg` | `ui_kit/lib/src/generated/assets.gen.dart` |
| Analytics | One `XAnalytics` class per screen, called from the cubit; `<event>_<screen>` ≤ 40 chars | own tracker in `core` (log-only for the test app) | `ui/<screen>/<screen>_analytics.dart` |
| Configuration | `EnvironmentType` + `--dart-define-from-file`, flavors `dev` / `prod` | — | `core/lib/src/constants/`, `envs/` |
| Testing | Unit tests for interactors and cubits, widget tests by `Semantics` id; Maestro for e2e | `flutter_test` + `mocktail` (no `bloc_test`) | `<package>/test/` |
| Lints / formatting | Strict casts, promoted lints, line length 120 | `flutter_lints` | root `analysis_options.yaml` |

---

## 1. Overall layout: a Dart workspace (monorepo)

One repository, many packages, one shared dependency resolution.

```
<repo>/
├── pubspec.yaml            # workspace root: name: _, members list, VERSIONS of all dependencies
├── analysis_options.yaml   # shared lints, line length 120
├── build.yaml              # global codegen options (freezed line_length: 120)
├── .fvmrc                  # Flutter version (gitignored; everyone runs `fvm use <version>`)
├── envs/                   # gitignored: dev_configurations.json, prod_configurations.json
├── mobile/                 # app shell: entry point, flavors, native projects
├── packages/
│   ├── core/               # leaf package: DI, analytics, network, storage, Failure, environment
│   ├── ui_kit/             # leaf package: theme, colors, typography, widgets, assets
│   ├── common/             # composition root: DI registration of all features, localization, wrappers, SafeCubitWrapper
│   └── router/             # all routes (go_router + go_router_builder)
├── features/
│   ├── <name>_feature/     # every feature is its own package; clean architecture data → domain → ui
│   └── ...
├── tools/                  # codegen scripts: flutter_gen.sh, tr_keys_gen.sh
└── .maestro/               # end-to-end UI tests (Maestro)
```

**Workspace rules:**
- Every member `pubspec.yaml` has `resolution: workspace` and `publish_to: 'none'`.
- Package versions are pinned in the **root** `pubspec.yaml`. Members list a package without a version (`dio:`)
  or with the same version.
- Run every command through `fvm`: `fvm flutter pub get`, `fvm flutter test`.
- Tests run **inside the package**: `cd features/x && fvm flutter test`. The root has no tests.

## 2. Packages: responsibilities and who imports whom

| Package | Responsibility | Must NOT contain |
|---|---|---|
| `core` | `DependencyProvider` (get_it wrapper), `EnvironmentType`, `dart_defines.dart`, `Failure` + fpdart `Either`, `ApiClient` (dio), storage (shared_preferences), analytics (`AnalyticsTrackerFactory`), crash reporting, plugin wrappers (permission, share, vibration…) | Feature imports, UI logic |
| `ui_kit` | `AppTheme`, `AppThemeProvider`, `AppColorScheme`, `AppTextStyles`, `AppIcons`, shared widgets (buttons, loaders), assets + `assets.gen.dart` (flutter_gen), fonts | Business logic, plugins, imports of other workspace packages |
| `common` | `MainDependenciesModuleResolver` (registers core and every feature), `ApplicationInitializer` (async startup), localization (`langs/*.json`, `LocaleKeys`), `LocalizationsWrapper`, `SafeCubitWrapper`, mixins (snackbar, dialog, bottom sheet), shared wrappers | New business logic (it only wires things together) |
| `router` | `GoRouterConfig.config`, typed routes in `routes_generator.dart`, `RouteModel`, `buildPlatformPage`, `context.pushTo/goTo` extensions | UI or business logic, guards, redirects (the splash screen is the gate) |
| `features/*` | One business area: its own data/domain/ui, pages, cubits, per-screen analytics | Direct dependencies on other features (rare exception: one feature exports an interface through its barrel) |
| `mobile` | `main.dart`, `main_common.dart` (`run()`), `app.dart` (`MaterialApp.router`), flavors, Firebase config, icons, splash | Business logic |

**Dependency direction:**
```
mobile ──► core, ui_kit, common, router (+ features that bring plugins)
common ──► core, ui_kit, router, all features      (registers their DI)
router ──► core, ui_kit, common, all features      (builds their pages)
feature ──► core, ui_kit, common, router
core, ui_kit ──► nothing from the workspace
```
Features import `router` and `common`, and those import the features. This cycle exists on purpose, only at the
barrel-file level, and Dart workspaces allow it. A feature **never** imports another package's `src/`, only its
barrel (`package:x/x.dart`).

When two features need shared state, put it in `core` (for example a small interactor) instead of adding a
feature → feature dependency.

## 3. Anatomy of a feature (mandatory structure)

Reference in our repo: `features/settings_feature`.

```
features/<name>_feature/
├── pubspec.yaml
├── CLAUDE.md                                   # short: what the feature does, key decisions
├── lib/
│   ├── <name>_feature.dart                     # barrel: export 'src/data/index.dart'; 'src/domain/index.dart'; 'src/ui/index.dart';
│   └── src/
│       ├── data/
│       │   ├── index.dart                      # exports ONLY the DI resolver and repository interfaces
│       │   ├── di/<name>_data_dependency_module_resolver.dart
│       │   ├── repository/
│       │   │   ├── <x>_repository.dart          # abstract interface class XRepository
│       │   │   ├── <x>_repository_impl.dart     # class XRepositoryImpl implements XRepository
│       │   │   └── mapper/                      # DTO ↔ Entity (XMapper + XMapperImpl)
│       │   ├── source/ (or database_source/)    # local_source/, remote_source/: XSource + XSourceImpl
│       │   ├── dto/                             # *Response (json_serializable), DB models
│       │   └── errors/                          # freezed unions for data-layer errors
│       ├── domain/
│       │   ├── index.dart                      # DI resolver, entities, failures, interactor interfaces
│       │   ├── di/<name>_domain_dependency_module_resolver.dart
│       │   ├── entity/                          # XEntity (plain or freezed)
│       │   ├── failure/                         # class XFailure extends Failure
│       │   └── interactor/
│       │       ├── <x>_interactor.dart          # abstract interface class XInteractor
│       │       └── <x>_interactor_impl.dart     # business rules, orchestrates several repositories
│       └── ui/
│           ├── index.dart                      # DI resolver + *_page.dart
│           ├── di/<name>_ui_dependency_module_resolver.dart
│           └── <screen>/
│               ├── <screen>_page.dart           # StatelessWidget + BlocProvider
│               ├── <screen>_analytics.dart      # screen analytics
│               ├── state/
│               │   ├── <screen>_cubit.dart
│               │   └── <screen>_state.dart      # part of '<screen>_cubit.dart'
│               ├── widgets/                     # private screen widgets (classes!)
│               └── models/                      # *UiModel for presentation
└── test/
    ├── data/  domain/  ui/                      # mirrors lib/src, files named <class_snake>_test.dart
```

**Call chain:** `Page` → `Cubit` → `Interactor` → `Repository` → `Source` (`ApiClient` / storage from `core`).
- A cubit never calls a repository directly, only through an interactor.
- The interactor orchestrates steps and rules. The repository performs single operations (fetch/save) and makes
  no decisions.
- Every layer is an "interface + Impl" pair. Dependencies come in through the constructor as `required` named
  parameters and are stored in private `_x` fields.
- Errors: the repository or interactor returns `Future<Either<Failure, T>>` (fpdart), catches exceptions inside,
  maps them to a `Failure` and reports them to `CrashReportingService`.

## 4. State: Cubit + freezed

- **Cubit only**, no Bloc events. Cubits extend `SafeCubitWrapper<State>` from `common`, which prevents `emit`
  after `close`.
- The state is **a single freezed class** with `@Default` fields and a status enum (`loading / loaded / failed`).
  Computed getters go after `const XState._();`.
- Freezed unions are used only for one-shot UI events (show a snackbar). They are consumed by
  `BlocConsumer`/`BlocListener` with `listenWhen`.
- Cubit and state sit in two files but form one library: `part 'x_cubit.freezed.dart'; part 'x_state.dart';`.

```dart
// ui/tutorials/state/tutorials_cubit.dart
part 'tutorials_cubit.freezed.dart';
part 'tutorials_state.dart';

class TutorialsCubit extends SafeCubitWrapper<TutorialsState> {
  final TutorialsAnalytics _analytics;
  final TutorialsInteractor _interactor;

  TutorialsCubit({required TutorialsAnalytics analytics, required TutorialsInteractor interactor})
    : _analytics = analytics,
      _interactor = interactor,
      super(const TutorialsState());

  Future<void> load() async {
    emit(state.copyWith(status: TutorialsLoadStatus.loading));
    // ... _interactor.fetchTutorials() → loaded / failed
  }

  void onBackClick() => _analytics.onBackClick();
}

// ui/tutorials/state/tutorials_state.dart
part of 'tutorials_cubit.dart';

enum TutorialsLoadStatus { loading, loaded, failed }

@freezed
abstract class TutorialsState with _$TutorialsState {
  const TutorialsState._();

  const factory TutorialsState({
    @Default(TutorialsLoadStatus.loading) TutorialsLoadStatus status,
    @Default(<Tutorial>[]) List<Tutorial> tutorials,
  }) = _TutorialsState;
}
```

**The page** creates its cubit itself (not the router) and takes it from DI:

```dart
class TutorialsPage extends StatelessWidget {
  const TutorialsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<TutorialsCubit>(
    create: (context) => DependencyProvider.get<TutorialsCubit>()..load(),
    child: const _TutorialsView(),
  );
}
```

The page subscribes to state with `BlocBuilder`, `BlocSelector` (preferred, it narrows rebuilds), `BlocListener` or
`BlocConsumer`, using `buildWhen`/`listenWhen`. Cubit methods are called through `context.read<XCubit>()`.

## 5. Dependency injection

`DependencyProvider` in `core` is a static wrapper over `GetIt.instance`. Methods: `get`, `getOrNull`,
`getWithParams`, `registerFactory`, `registerLazySingleton`, `registerFactoryWithParams`, `isRegistered`.

Every feature has **three resolvers**, one per layer:

```dart
abstract interface class SettingsDomainDependencyModuleResolver {
  static void register() {
    _tutorialsInteractor();
  }

  static void _tutorialsInteractor() {
    DependencyProvider.registerFactory<TutorialsInteractor>(
      () => TutorialsInteractorImpl(repository: DependencyProvider.get<TutorialsRepository>()),
    );
  }
}
```

- `registerFactory` is the default: repositories, interactors, cubits and analytics classes.
- `registerLazySingleton` is for services and anything that holds state across screens (DB sources, caches).
- `registerFactoryWithParams` is for cubits that take a runtime parameter (`getWithParams(param1: id)`). That
  constructor parameter **must be `required`**.
- All resolvers are called from `common/lib/src/di/main_dependencies_module_resolver.dart` in this order: core, then
  data → domain → ui for each feature. A new feature adds its `_xFeatureRegister()` there, and `common` adds the
  feature to its `pubspec.yaml`.
- After registration, `ApplicationInitializer.initialize()` runs the async startup (Remote Config, crash handlers,
  migrations).

## 6. Navigation: go_router + go_router_builder

All routes are declared in one place: `packages/router/lib/src/routes_generator.dart`.

```dart
@TypedGoRoute<TutorialsRoute>(name: TutorialsRoute.name, path: TutorialsRoute.path)
@immutable
class TutorialsRoute extends GoRouteData with $TutorialsRoute implements RouteModel {
  static const String name = 'TutorialsPage';
  static const String path = '/tutorials';

  const TutorialsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildPlatformPage(state: state, child: const TutorialsPage());
}
```

- `buildPlatformPage` returns a Material page on Android and a Cupertino page on iOS.
- Bottom tab navigation is a `@TypedStatefulShellRoute` with one `TypedStatefulShellBranch` per tab; each branch has
  its own `navigatorKey` from `GoRouterConfig`.
- Entry point: `initialLocation: '/splash'`. The splash decides where to go next (onboarding or home).
- A feature navigates with `import 'package:router/router.dart'` and calls `context.pushTo(const TutorialsRoute())`,
  `context.goTo(...)` or `context.maybePop()`.
- After changing routes, run `build_runner` in `packages/router`.

> Don't copy one thing: our `build_context_ext.dart` dispatches routes through `if (route is X)` ladders. In the new
> app, make `pushTo/goTo` a thin wrapper over the generated `route.push(context)` / `route.go(context)`.

## 7. Models and codegen

- **freezed**: states, entities with logic, UI models, error unions.
- **json_serializable**: API DTOs only (`*Response` with `fromJson`/`toJson`) in `data/dto/`. Domain entities don't
  depend on JSON; a mapper turns a DTO into an entity.
- **go_router_builder**: routes in `router`.
- **flutter_gen**: `ui_kit` assets → `lib/src/generated/assets.gen.dart` (`./tools/flutter_gen.sh`).
- **easy_localization keys**: `LocaleKeys` (`./tools/tr_keys_gen.sh`).
- Run `build_runner` **from the owning package**: `cd features/x && fvm dart run build_runner build -d`. A run from
  the root silently generates nothing. After codegen always run `fvm dart format . --line-length 120` from the
  root.
- Generated files (`*.g.dart`, `*.freezed.dart`) are never edited by hand.

Root `build.yaml`:
```yaml
global_options:
  freezed:freezed:
    options:
      line_length: 120
```

## 8. Theme, UI, localization, analytics

- **Material/Cupertino** come from the `material_ui` and `cupertino_ui` packages, **never** from
  `package:flutter/material.dart` or `cupertino.dart`. Every package that uses them declares them in its own
  `pubspec.yaml`.
- **Theme**: `AppThemeProvider(theme: AppTheme.main())` wraps the app. In widgets use `context.colors.x`,
  `context.texts.x`, `context.icons.x`. Hardcoded colors and text styles are not allowed.
- **Localization**: `easy_localization`, JSON files in `packages/common/lib/src/localization/langs/` (`en.json` +
  one more language is enough for the test app). Every user-facing string is `LocaleKeys.someKey.tr()`.
  `MaterialApp.router` gets `localizationsDelegates: context.appLocalizationDelegates`.
- **Analytics**: every screen has an `XAnalytics` class with `static const _screenName = 'x_page'` and an event enum.
  An event is composed as `<event>_<screenName>`, 40 characters max in total. The cubit calls analytics, not the
  widget. In the test app the tracker can be an implementation that just logs (`dart:developer log`), but the
  structure stays the same.
- **UI testability**: every interactive widget is wrapped in `Semantics(identifier: 'screen_element', button: true)`
  so Maestro can find it.

## 9. Code rules (lints + conventions)

`analysis_options.yaml`: `include: package:flutter_lints/flutter.yaml`, `strict-casts: true`,
`strict-raw-types: true`, `formatter: page_width: 120`. Promoted to errors: `unused_import`,
`missing_required_param`, `must_be_immutable`, `missing_enum_constant_in_switch`, `sort_child_properties_last`,
`missing_dependency`, `invalid_dependency`. Enabled as warnings: `always_use_package_imports`,
`prefer_const_constructors`, `require_trailing_commas`, `prefer_final_locals`, `avoid_print`.

Conventions the linter doesn't catch:
1. **`package:` imports only**, no relative imports.
2. **No functions that return a `Widget`** (`Widget _buildHeader()`). Use separate `StatelessWidget`/`StatefulWidget`
   classes.
3. **No nested ternaries.** Use `if/else` or `switch` for several branches.
4. **Records have at most 2 fields.** From 3 fields on, create a class or a freezed model.
5. **`!` (force unwrap) only when non-null is proven right there** (a guard on the line above). For data from the
   network, JSON or async sources use `?.`, `??`, an early return or pattern matching.
6. **`BuildContext` after `await`** only after checking `context.mounted`.
7. **Comments explain "why", not "what".** No comment by default, and no large dartdoc templates.
8. `const` constructors wherever possible.

## 10. Packages (priority list)

Use these packages. Add a different one only when nothing here fits.

| Purpose | Package | Our version |
|---|---|---|
| State | `flutter_bloc` | ^9.1.1 |
| DI | `get_it` (through `DependencyProvider`) | ^9.2.1 |
| Models | `freezed` / `freezed_annotation` | ^3.2.3 / ^3.1.0 |
| JSON | `json_serializable` / `json_annotation` | ^6.11.2 / ^4.9.0 |
| Either / FP | `fpdart` | ^1.2.0 |
| Navigation | `go_router` + `go_router_builder` | ^18.0.1 / ^4.2.0 |
| Network | `dio` | ^5.8.0 |
| Local key-value | `shared_preferences` | ^2.5.4 |
| Local DB | `objectbox` + `objectbox_flutter_libs` + `objectbox_generator` | ^5.3.0 |
| Localization | `easy_localization` (+ `intl`) | ^3.0.8 |
| Material / Cupertino | `material_ui` / `cupertino_ui` | ^1.4.0 / ^1.1.1 |
| SVG / assets | `flutter_svg`, `flutter_gen_runner` | ^2.2.4 / ^5.13.0 |
| Reactive | `rxdart` | ^0.28.0 |
| Utilities | `collection`, `path`, `path_provider`, `url_launcher`, `package_info_plus`, `connectivity_plus` | — |
| Images | `image_picker`, `flutter_cache_manager` | — |
| Loaders | `shimmer` | ^4.0.0 |
| Tests | `flutter_test` + `mocktail` (no `bloc_test`) | ^1.0.4 |
| Codegen | `build_runner` | ^2.12.2 |
| Lints | `flutter_lints` | ^6.0.0 |
| Icons / splash | `flutter_launcher_icons`, `flutter_native_splash` | — |

Firebase, RevenueCat, AppsFlyer and PostHog are **not needed** for the test app. Analytics and crash reporting can
be interfaces in `core` with a simple logging implementation.

## 11. `pubspec.yaml` templates

The real files of every package are in Appendix A.

**Root:**
```yaml
name: _
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
  flutter: 3.47.5

workspace:
  - packages/core
  - packages/ui_kit
  - packages/common
  - packages/router
  - features/<a>_feature
  - features/<b>_feature
  - mobile

dependencies:          # VERSIONS live here; members reference packages without a version
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  get_it: ^9.2.1
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  fpdart: ^1.2.0
  dio: ^5.8.0+1
  shared_preferences: ^2.5.4
  # ...

dev_dependencies:
  flutter_lints: ^6.0.0
  freezed: ^3.2.3
  build_runner: ^2.12.2
  json_serializable: ^6.11.2
  go_router_builder: ^4.2.0
```

**Feature (`features/<name>_feature/pubspec.yaml`):**
```yaml
name: <name>_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  core:
  ui_kit:
  common:
  router:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

**core:** `flutter`, `material_ui`, `freezed_annotation`, `json_annotation`, `get_it`, `fpdart`, `dio`,
`shared_preferences` and **every Flutter plugin**. A plugin must be declared in a package that `mobile` depends on
transitively, otherwise it won't be registered on Android/iOS.
**ui_kit:** `flutter`, `material_ui`, `cupertino_ui`, `flutter_svg`, `shimmer`. Dev: `flutter_gen_runner`. Plus a
`flutter_gen:` block (output `lib/src/generated/`, `line_length: 120`, `package_parameter_enabled: true`) and
`flutter: assets:` listing **every** subfolder (asset folders are not recursive).
**common:** `core`, `ui_kit`, `router`, all features, `easy_localization`, `freezed_annotation`, and
`flutter: assets: - lib/src/localization/langs/`.
**router:** `core`, `ui_kit`, `common`, all features, `go_router`, `material_ui`, `cupertino_ui`. Dev:
`build_runner`, `go_router_builder`.
**mobile:** `core`, `ui_kit`, `common`, `router`, `material_ui`, `flutter_native_splash`, `flutter_launcher_icons`.

## 12. App shell (`mobile/`)

- `main.dart` only calls `run(environment: ...)`. The environment comes from
  `--dart-define-from-file=../envs/dev_configurations.json` (`String.fromEnvironment` in
  `core/lib/src/constants/dart_defines.dart`).
- `main_common.dart` → `run()` runs these steps in order:
  1. `WidgetsFlutterBinding.ensureInitialized()`.
  2. In debug: `ensureSemantics()` for Maestro.
  3. `EasyLocalization.ensureInitialized()`.
  4. `MainDependenciesModuleResolver.register(environment:)`.
  5. `ApplicationInitializer.initialize()`.
  6. `runApp(const LocalizationsWrapper(child: App()))`.
- `app.dart` builds `AppThemeProvider(AppTheme.main())` → `MaterialApp.router(routerConfig: GoRouterConfig.config,
  localizationsDelegates: ..., supportedLocales: ...)`.
- `dev` and `prod` flavors are Android `productFlavors`; `dev` adds `applicationIdSuffix ".dev"`.
- `EnvironmentType { dev, prod }` with an `isDebug` getter lives in `core`.

## 13. Tests

- Location: `<package>/test/{data,domain,ui}/<class_snake>_test.dart`.
- Tools: `flutter_test` + `mocktail` (`class _MockX extends Mock implements X {}`).
- Cubit tests build the cubit directly with mocks, call its methods, check `cubit.state` and
  `verify(() => analytics.onX())`. The cubit is closed in `tearDown`.
- Minimum for the test app: unit tests for every feature's interactors and cubits, and one widget test per page that
  finds a widget by its `Semantics` identifier.

## 14. Before opening a PR

```bash
fvm dart format . --line-length 120          # from the root, whole project
fvm flutter analyze                          # must be clean
cd features/<x> && fvm flutter test          # in every changed package
grep -rnE "package:flutter/(material|cupertino)\.dart" mobile packages features   # must print nothing
```

## 15. Checklist: "the structure is reproduced"

- [ ] Dart workspace: root `name: _`, every member has `resolution: workspace`, versions live in the root.
- [ ] Packages `core`, `ui_kit`, `common`, `router`, `mobile` exist, plus at least 2–3 features in `features/`.
- [ ] Every feature has `data/domain/ui`, an `index.dart` in each layer, and a barrel `lib/<name>_feature.dart`.
- [ ] Repository, Interactor and Source are "interface + Impl" pairs returning `Either<Failure, T>`.
- [ ] Three DI resolvers per feature, all called from `MainDependenciesModuleResolver`.
- [ ] Cubits extend `SafeCubitWrapper`, state is freezed, `BlocProvider` is created in the Page through `DependencyProvider`.
- [ ] All routes are typed in `router`, use `buildPlatformPage`, tabs via `StatefulShellRoute`, a splash as the entry point.
- [ ] Theme through `context.colors/texts`, assets through flutter_gen, strings through `LocaleKeys.x.tr()`.
- [ ] An `XAnalytics` class per screen, called from the cubit.
- [ ] `Semantics(identifier: ...)` on interactive widgets.
- [ ] Lints and conventions from section 9 hold, `analyze` is clean, tests are green.

---

## Appendix A. Real `pubspec.yaml` of every Inspiro package

Snapshot of the repository as of 2026-10-11. The font and asset-folder lists in `ui_kit` are shortened. `forks/*` (patched third-party packages) are left out because the test app doesn't need them.

### `pubspec.yaml`

```yaml
name: _
description: "Best photo editing app"
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
  flutter: 3.47.5

workspace:
  - packages/core
  - packages/router
  - packages/ui_kit
  - packages/common
  - features/stickers_feature
  - features/fonts_feature
  - features/presets_feature
  - features/main_shell_feature
  - features/new_project_editor_feature
  - features/settings_feature
  - features/purchases_feature
  - features/rate_us_feature
  - features/whats_new_feature
  - features/notifications_feature
  - features/force_update_feature
  - mobile
  - forks/color_picker_plus
  - forks/live_reorderable_list

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  get_it: ^9.2.1
  freezed_annotation: ^3.1.0
  path_provider: ^2.1.5
  path: ^1.9.1
  archive: ^4.0.9
  fpdart: ^1.2.0
  rxdart: ^0.28.0
  json_annotation: ^4.9.0
  flutter_keyboard_visibility: ^7.0.1
  collection: ^1.19.1
  permission_handler: ^12.0.1
  image_picker: ^1.2.4
  intl: ^0.20.2
  shared_preferences: ^2.5.4
  scrollable_positioned_list: ^0.3.8
  url_launcher: ^6.3.2
  youtube_player_iframe: ^6.0.2
  appsflyer_sdk: ^6.18.1
  airbridge_flutter_sdk: ^4.10.0
  dio: ^5.8.0+1
  flutter_multi_formatter: ^2.13.10
  package_info_plus: ^10.2.1
  posthog_flutter: ^5.24.2
  vibration: ^3.1.8
  purchases_ui_flutter: ^10.3.0
  flutter_cache_manager: ^3.4.1
  connectivity_plus: ^6.1.0

  #firebase
  firebase_remote_config: ^6.2.0
  firebase_core: ^4.5.0
  firebase_analytics: ^12.1.3
  firebase_crashlytics: ^5.0.8
  firebase_storage: ^13.1.0
  cloud_firestore: ^6.1.3
  firebase_app_check: ^0.4.1+5
  firebase_messaging: ^16.1.2
  firebase_app_installations: ^0.4.0+7

  # local db
  objectbox: ^5.3.0
  objectbox_flutter_libs: ^5.3.1
  super_clipboard: ^0.9.1

# super_native_extensions 0.9.1 (via super_clipboard) caps device_info_plus below 12, i.e. on win32 5, while
# file_picker 13 needs win32 6. It only reads `version.sdkInt`, which 13.x keeps. Drop once a stable
# super_clipboard allows device_info_plus 13.
dependency_overrides:
  device_info_plus: ^13.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  custom_lint: ^0.8.1
  freezed: ^3.2.3
  build_runner: ^2.12.2
  build_verify: ^3.1.1
  yaml_edit: ^2.2.4
  yaml: ^3.1.3
  json_serializable: ^6.11.2
  go_router_builder: ^4.2.0
  objectbox_generator: ^5.3.0

flutter:
  uses-material-design: true
  config:
    # Repeated from mobile/pubspec.yaml: the tool reads this from whichever directory it runs in.
    enable-swift-package-manager: true
```

### `mobile/pubspec.yaml`

```yaml
name: inspiro
publish_to: 'none'

version: 2.2.0+230
environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  common:
  core:
  ui_kit:
  router:
  notifications_feature:
  rate_us_feature:
  purchases_feature:
  force_update_feature:
  firebase_core:
  firebase_app_check:
  objectbox_flutter_libs: ^5.3.1
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.7
  app_tracking_transparency: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  xml: ^6.6.1

flutter_launcher_icons:
  android: true
  ios: true
  remove_alpha_ios: true
  image_path: "assets/png/appIcon.png" # icon used only for generating app icon
  min_sdk_android: 30

flutter_native_splash:
  color: "#161619"
  image: ../packages/ui_kit/assets/main_theme/png/splash.png
  android_12:
    image: ../packages/ui_kit/assets/main_theme/png/android12splash.png
    color: "#161619"
    color_dark: "#161619"
    icon_background_color: "#161619"
    icon_background_color_dark: "#161619"
  fullscreen: true
  android: true
  ios: true
  web: false

flutter:
  uses-material-design: true
  config:
    # Project level, so CI and every machine agree regardless of their global flutter config.
    # Plugins without a Package.swift still build through CocoaPods (see mobile/CLAUDE.md).
    enable-swift-package-manager: true
```

### `packages/common/pubspec.yaml`

```yaml
name: common
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  objectbox: ^5.3.0
  core:
  ui_kit:
  router:
  inspiro:
  stickers_feature:
  settings_feature:
  fonts_feature:
  main_shell_feature:
  purchases_feature:
  rate_us_feature:
  notifications_feature:
  force_update_feature:
  flutter_color_picker_plus:
  presets_feature:
  new_project_editor_feature:
  easy_localization: ^3.0.8
  webview_flutter: ^4.13.1
  appsflyer_sdk: ^6.17.8
  flutter_cache_manager:
  flutter_svg:
  http: ^1.6.0

dev_dependencies:
  cupertino_ui: ^1.1.1
  app_links_platform_interface: ^2.0.2
  build_runner: ^2.12.2
  file: ^7.0.1
  freezed: ^3.2.3
  objectbox_generator: ^5.3.0
  json_serializable: ^6.11.2
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  assets:
    - lib/src/localization/langs/
```

### `packages/core/pubspec.yaml`

```yaml
name: core
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0

  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0

  firebase_core:
  cloud_firestore:
  firebase_analytics:
  firebase_app_installations:
  firebase_remote_config:
  firebase_storage:
  firebase_crashlytics:
  firebase_messaging:

  appsflyer_sdk:
  airbridge_flutter_sdk:
  posthog_flutter:
  facebook_app_events: ^0.28.0
  vibration:
  permission_handler:
  package_info_plus:
  mailer: ^7.1.0
  purchases_flutter: ^10.3.0
  in_app_review: ^2.0.11
  share_plus: ^13.3.0
  app_links: ^7.0.0
  super_clipboard:
  gal: ^2.3.2
  file_picker: ^13.1.0
  image_picker: ^1.2.4
  image_picker_android: ^0.8.13
  image_picker_platform_interface: ^2.11.0
  flutter_image_compress: ^2.5.1
  flutter_svg:
  image: ^4.5.4
  dio: 5.9.2
  objectbox: ^5.3.0
  objectbox_flutter_libs: ^5.3.1
  connectivity_plus:
  device_info_plus:

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.12.2
  freezed: ^3.2.3
  json_serializable: ^6.11.2
  mocktail: ^1.0.4
  firebase_app_installations_platform_interface: ^0.1.4+66
  firebase_core_platform_interface: ^6.0.2
  cross_file: ^0.3.5+5
  plugin_platform_interface: ^2.1.8
  permission_handler_platform_interface: ^4.3.0
  package_info_plus_platform_interface: ^4.1.0
  path_provider_platform_interface: ^2.1.2

flutter:
  uses-material-design: true
```

### `packages/router/pubspec.yaml`

```yaml
name: router
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  cupertino_ui: ^1.1.1
  common:
  ui_kit:
  core:
  stickers_feature:
  fonts_feature:
  force_update_feature:
  presets_feature:
  main_shell_feature:
  new_project_editor_feature:
  settings_feature:
  purchases_feature:
  rate_us_feature:
  whats_new_feature:
  go_router: ^18.0.1
  notifications_feature:

dev_dependencies:
  build_runner: ^2.12.2
  go_router_builder: ^4.2.0
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
```

### `packages/ui_kit/pubspec.yaml`

```yaml
name: ui_kit
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  cupertino_ui: ^1.1.1
  syncfusion_flutter_sliders: ^32.2.8
  syncfusion_flutter_core: ^32.2.8
  shimmer: ^4.0.0
  flutter_svg: ^2.2.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_gen_runner: ^5.13.0

flutter_gen:
  assets:
    outputs:
      package_parameter_enabled: true
  output: lib/src/generated/
  line_length: 120

  # Optional
  integrations:
    flutter_svg: true

flutter:
  uses-material-design: true
  assets:
    - assets/main_theme/webp/
    - assets/main_theme/webp/font_pairs/classic/
    - assets/main_theme/webp/font_pairs/decorative/
    # ... every assets/ subfolder is listed separately (not recursive)
  fonts:
    # ... ~40 custom fonts: - family: <Name> / fonts: - asset: assets/custom_fonts/<Name>/<file>.otf
```

### `features/fonts_feature/pubspec.yaml`

```yaml
name: fonts_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  cupertino_ui: ^1.1.1
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  objectbox: ^5.3.0
  core:
  ui_kit:
  common:
  router:
  flutter_keyboard_visibility:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  objectbox_generator: ^5.3.0
  json_serializable: ^6.11.2
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

### `features/force_update_feature/pubspec.yaml`

```yaml
name: force_update_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  flutter_bloc:
  fpdart: ^1.2.0
  url_launcher: ^6.3.2
  flutter_native_splash: ^2.4.7
  core:
  ui_kit:
  common:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  go_router:
```

### `features/main_shell_feature/pubspec.yaml`

```yaml
name: main_shell_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  core:
  ui_kit:
  common:
  router:
  whats_new_feature:
  fonts_feature:
  rate_us_feature:
  purchases_feature:
  notifications_feature:
  stickers_feature:
  force_update_feature:
  new_project_editor_feature:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  fpdart: ^1.2.0
```

### `features/new_project_editor_feature/pubspec.yaml`

```yaml
name: new_project_editor_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  live_reorderable_list:
  flutter_bloc: ^9.1.1
  flutter_staggered_grid_view: ^0.7.0
  fpdart:
  freezed_annotation: ^3.1.0
  objectbox: ^5.3.0
  core:
  ui_kit:
  common:
  router:
  stickers_feature:
  fonts_feature:
  presets_feature:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  objectbox_generator: ^5.3.0
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

### `features/notifications_feature/pubspec.yaml`

```yaml
name: notifications_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  core:
  ui_kit:
  common:
  router:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

### `features/presets_feature/pubspec.yaml`

```yaml
name: presets_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  objectbox: ^5.3.0
  core:
  ui_kit:
  common:
  router:
  purchases_feature:
  synchronized: ^3.1.0  # For export serialization lock

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  objectbox_generator: ^5.3.0
  mocktail: ^1.0.4

flutter:
  shaders:
    - shaders/preset_unified.glsl
    - shaders/preset_postprocess.glsl
    - shaders/preset_blur.glsl
    - shaders/preset_upsample.glsl
```

### `features/purchases_feature/pubspec.yaml`

```yaml
name: purchases_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  core:
  ui_kit:
  common:
  router:
  purchases_ui_flutter:
  flutter_carousel_widget: ^3.1.0

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

### `features/rate_us_feature/pubspec.yaml`

```yaml
name: rate_us_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  fpdart: ^1.2.0
  in_app_review: ^2.0.11
  freezed_annotation: ^3.1.0
  core:
  ui_kit:
  common:
  router:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

### `features/settings_feature/pubspec.yaml`

```yaml
name: settings_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  cupertino_ui: ^1.1.1
  freezed_annotation: ^3.1.0
  core:
  ui_kit:
  common:
  router:
  rate_us_feature:
  youtube_player_iframe:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

### `features/stickers_feature/pubspec.yaml`

```yaml
name: stickers_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  objectbox: ^5.3.0
  core:
  ui_kit:
  common:
  rxdart:
  router:

dev_dependencies:
  flutter_test:
    sdk: flutter
  # Widget tests mock the prefs channel easy_localization's ensureInitialized reads.
  shared_preferences: any
  mocktail: ^1.0.4
  build_runner: ^2.12.2
  freezed: ^3.2.3
  objectbox_generator: ^5.3.0
  json_serializable: ^6.11.2
```

### `features/whats_new_feature/pubspec.yaml`

```yaml
name: whats_new_feature
publish_to: 'none'

environment:
  sdk: '>=3.8.0 <4.0.0'
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.4.0
  freezed_annotation: ^3.1.0
  core:
  ui_kit:
  common:
  router:

dev_dependencies:
  build_runner: ^2.12.2
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  shared_preferences: any
```
