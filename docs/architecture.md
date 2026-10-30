# Current Tricount architecture

Based on the [Inspiro guide](inspiro-architecture-guide.md). The [future module map](tricount-architecture.md)
is separate from the implemented shell described below.

## Implemented structure

Dart workspace with one shared `pubspec.lock`; dependency versions are constrained in the root `pubspec.yaml`.
Each member uses `resolution: workspace`, `publish_to: 'none'`, and its own `lib/` and `test/` as needed.

| Path | Responsibility |
|---|---|
| `mobile/` | The `mobile` Flutter app: entry points, App, Android/iOS, dev/prod flavors, integration widget tests |
| `packages/core/` | get_it DI facade, EnvironmentType, Failure, API/preferences wrappers, safe analytics, startup readiness |
| `packages/ui_kit/` | AppThemeProvider, context.colors/texts/icons, shared loading indicator, generated SVG assets |
| `packages/common/` | DI composition, ApplicationInitializer, SafeCubitWrapper, Ukrainian/English localization |
| `packages/router/` | Typed splash/tab routes, separate Navigators, navigation extensions |
| `features/splash_feature/` | Readiness checks, loading/loaded/failed, retry after failure, transition to home |
| `features/main_shell_feature/` | Two-tab shell, placeholder pages, data/domain/ui resolvers |
| `features/home_feature/` | Existing home screen, state, and opened event; no financial features |
| `envs/` | Safe dev/prod examples; private configurations are ignored by Git |
| `tools/` | Workspace commands, codegen, localization, formatting, analysis, and tests |
| `.maestro/` | Startup verification scenario for the installed dev app |

## Dependencies and flow

`core` and `ui_kit` do not import other workspace packages. `mobile` composes common, router, and ui_kit.
`common` registers feature DI; router builds feature pages. Features access the public common,
core, router, and ui_kit barrels. The common ↔ feature ↔ router relationships follow the reference guide;
importing another package's `src/` is prohibited. Direct feature → feature imports are prohibited.
Add future shared contracts to core.

Startup: binding → ensureSemantics in debug only → await EasyLocalization.ensureInitialized() →
await SystemChrome.setPreferredOrientations([portraitUp]) → DI (core, then each feature's data → domain → ui) →
await ApplicationInitializer.initialize() → runApp(LocalizationsWrapper(child: App())) → splash → tabs.
The initializer installs error handlers and marks StartupStatus ready before runApp.
Repeated calls do not reinstall handlers; there is no microtask or cached Future.
If initialization fails, bootstrap records it through the local CrashReportingService and opens
the recovery shell: splash retries through the repository and offers a retry button on another failure.
StartupStatus becomes ready only after success.

ApplicationInitializer is a core contract, also exported through common.dart.
MainDependenciesModuleResolver registers its implementation as a lazy singleton. DI reset disposes it
and restores previous global handlers if the current instance still owns them.
FlutterError.onError forwards the error and stack to CrashReportingService with fatal: false,
then calls the previous Flutter handler. PlatformDispatcher.onError captures unhandled async errors
in the root isolate with fatal: true and preserves a previous handler's return value when present.
Without a previous handler, it returns whether local recording succeeded.
A reporter failure does not recursively report itself. Errors from other isolates must be forwarded separately;
no external SDK is connected.
Splash: `Page → Cubit → StartupInteractor → StartupRepository → StartupSource → StartupStatus`.
The result is `Either<Failure, Unit>`; errors are mapped to Failure. On success, a typed route replaces splash
with home. Pages create their Cubits through BlocProvider and DependencyProvider.
SafeCubitWrapper ignores async completions that emit after the page is closed.
Home does not yet need a repository/interactor; its data/domain resolvers do not register invented operations.

## Core contracts: DI and errors

The public import is `package:core/core.dart`. It exports `DependencyProvider`, abstract `Failure`,
and fpdart's `Either`, `Left`, and `Right`. Set get_it/fpdart versions in the root `pubspec.yaml`;
core lists these dependencies without versions. Keep business rules and features out of core.

`DependencyProvider` is a static facade over get_it:

| Method | Contract |
|---|---|
| `get<T>()` | Returns the registered T service; missing registration is an error |
| `getOrNull<T>()` | Returns null for an unregistered T; does not hide creation failures for registered services |
| `getWithParams<T>(param1: ..., param2: ...)` | Passes runtime parameters to a factory; values must match its registered P1/P2 types |
| `registerFactory<T>(factory)` | A new instance on each lookup |
| `registerLazySingleton<T>(factory, dispose: ...)` | One instance created on first lookup; optional disposal may be synchronous or asynchronous |
| `registerFactoryWithParams<T, P1, P2>(factory)` | Typed factory with two runtime parameters |
| `isRegistered<T>()` | Checks whether a registration exists |
| `reset()` | Returns `Future<void>`, clears registrations, and awaits disposal of instantiated singletons |

Always `await DependencyProvider.reset()`; tests may pass this method to `tearDown`.
Unused lazy singletons are not created merely for cleanup. The container does not retain factory instances;
their owner, such as BlocProvider, controls their lifecycle.

Domain/data operations with expected failure paths return `Either<Failure, T>` or
`Future<Either<Failure, T>>`: `Left(failure)` represents failure; `Right(value)` represents success.
Define concrete failures in the relevant scenario module and map exceptions at the data/domain boundary.
Cubits handle both branches through fold. The base Failure contains neither business logic nor user data.

## Local settings: PreferencesStorage

Consumers obtain `PreferencesStorage` through `DependencyProvider.get<PreferencesStorage>()`
from public `core.dart`; `PreferencesStorageImpl` is not exported from the barrel.
`CoreDependenciesModuleResolver` registers it as a lazy singleton and runs first in
`MainDependenciesModuleResolver`, also composing the other core services.

The wrapper uses `SharedPreferencesAsync` without a local cache. `readBool`, `readInt`, and
`readString` return `Future<bool?>`, `Future<int?>`, and `Future<String?>`; missing keys return null.
`writeBool`, `writeInt`, `writeString`, and `remove` return `Future<void>` and must be awaited.
Remove deletes only the specified key, never the entire store. Platform errors and type mismatches
are not hidden: the consumer's data/source handles them and maps them to Failure when needed.

Mobile calls `WidgetsFlutterBinding.ensureInitialized()` before DI registration;
Flutter's native registrant connects the plugin. SharedPreferencesAsync requires neither a separate
initialize()/getInstance() nor a getKeys() warm-up. Each operation directly awaits the corresponding
platform call, without caching values or a preparation Future.
Tests use the official in-memory async backend; shared_preferences_platform_interface is a test dependency
of core and mobile with its version constrained at the root.

The store is for noncritical settings, not financial records or secrets. The wrapper adds no business keys,
logs neither keys nor values, and does not change easy_localization's internal preference store.
There are no separate user-settings controls in the UI yet.

## UI, generation, and environments

UI imports standard `package:flutter/material.dart`; material_ui/cupertino_ui are not used directly.
buildPlatformPage supplies SDK MaterialPage on Android and CupertinoPage on iOS while retaining
Material widgets and the shared theme. Access styles through AppThemeProvider and context extensions;
strings use generated LocaleKeys and easy_localization. en/uk are supported: saved or supported system
language, with English fallback for unsupported languages and missing translations.
There is no language-selection screen yet. States use one freezed class with a status enum.
Routes use go_router_builder; assets use flutter_gen. Commit generated files and never edit them manually.

Android has dev/prod productFlavors; iOS has matching shared schemes and Debug/Profile/Release configurations.
Dev uses a separate application/bundle ID with `.dev`. ENVIRONMENT from dart-define must match the native flavor.
Examples contain no secrets. Production signing and store publishing are not configured.
Dev analytics locally records event names and technical properties; passing user data is prohibited.
CrashReportingService locally records error type, stack, and fatal, not arbitrary exception messages.

The network client and preferences are wrappers without active server requests or financial data.
Add ObjectBox, DTO/json_serializable, and business modules with the first agreed scenario that needs
those data/API/tabs; they are not implemented shell features.

## Base theme: ui_kit

One `AppTheme.main()` uses Flutter Material 3 with a basic blue seed.
`AppColorScheme` provides primary/onPrimary, surface/onSurface/onSurfaceVariant, outline, and error/onError.
`AppTextStyles` contains heading, title, body, label, and caption based on the standard TextTheme.
There are no font files or fontFamily overrides; typography uses Flutter's defaults.

`AppThemeProvider` is an InheritedWidget wrapping `MaterialApp.router` in mobile.
Set `theme.material` on MaterialApp; consumers read `context.colors` and `context.texts` through public
`ui_kit.dart`. Replacing the theme instance notifies dependent widgets; the closest provider wins.
Access without a provider throws an explicit StateError.
`context.icons` remains available for the current retry button. Add new colors/styles in ui_kit,
not independently on each screen.

Home/Splash widgets use Flutter Material; route pages use SDK MaterialPage / CupertinoPage.
Localization delegates come from SDK flutter_localizations and easy_localization, including Ukrainian.
Direct material_ui/cupertino_ui dependencies were removed from every workspace pubspec;
go_router 18.1.0 still depends on them transitively. Do not upgrade it for this task.

## Analytics and error logging

The analytics API in public `core.dart` exports `AnalyticsTracker`, `AnalyticsTrackerFactory`, and
`CrashReportingService`; their implementations are registered in core DI.
The factory creates trackers through `create(screenName: ...)`;
`getWithParams<AnalyticsTracker>(param1: screenName)` is also available.
Each tracker retains its screen name so different screens do not overwrite each other's context.

`track(eventName: ..., properties: ...)` builds `<event>_<screenName>`. The full name must contain
at most 40 characters. Violations throw ArgumentError before logging, without truncation.
Names and property keys must be nonempty `[a-z0-9_]+` identifiers.
`onBackClick()` uses the same path with `back_click` and empty properties; a long suffix may make
that event too long, in which case it is explicitly rejected too. Name validation applies even when logging is disabled.

Properties support only String, bool, finite numbers, and null; arbitrary objects are not serialized.
Use them only for technical flags such as source or retry. Do not pass names, contacts, amounts,
balances, tokens, or other personal/financial values. An allowed value type alone does not guarantee
privacy; check it at the call site. Home/Splash emit only opened from their event enum through their Cubits.

`recordError(error, stackTrace, {fatal: false})` receives the original error and its stack.
The local writer sends a safe error runtimeType in the error field of `dart:developer.log`,
the stack in stackTrace, and fatal in the message. It does not call arbitrary exception toString,
which could expose secrets or financial values from the message.
The splash repository forwards the original exception stack instead of creating a new stack when logging.

Only local `dart:developer.log` is used: event/properties are JSON in `tricount.analytics`;
errors use `tricount.errors`. Analytics is enabled only for dev; crash logs are local in both environments.
There is no external SDK or data transmission.

## Adding a feature

1. Agree on behavior from the screenshot. Create `features/<name>_feature` and register it in the workspace.
2. Add data/domain/ui, their index.dart files, and a public barrel. Export only contracts and DI;
   UI exports resolvers and pages. Source/Repository/Interactor use interface + Impl and required named parameters.
3. Register three resolvers in MainDependenciesModuleResolver; add common and router dependencies.
4. The Cubit extends SafeCubitWrapper and calls interactors and analytics, not repositories.
5. Add a typed route, LocaleKeys, Semantics identifiers for controls, and theme-based styles.
6. Run generation from the owning package and behavioral tests. Add a short feature CLAUDE.md in English.
7. Update this document, README, and commands when structure changes. Submit a PR to develop.

Installation, launch, and verification commands are in [README](../README.md).

## Tab shell and routes

GoRouterConfig.config creates a router with initialLocation: /splash. App reads config once and disposes it.
Root, home, and second Navigator keys are defined in GoRouterConfig; each TypedStatefulShellBranch
references its own key. MainShellRoute uses @TypedStatefulShellRoute with the standard IndexedStack.
MainShellPage receives child, currentIndex, and a callback; router calls goBranch without resetting
initialLocation. Switching tabs, including reselecting the active tab, preserves its stack.

After successful initialization, splash calls context.goTo(const HomeRoute()). go replaces the route,
so Back at a tab root does not reopen splash. No separate native splash has been added.
The first tab /home retains HomePage; the second /second contains a placeholder screen.
/home/details and /second/details are placeholders for verifying nested stacks, not expense scenarios.
Buttons open them through context.pushTo; Back closes a page only in the active Navigator.
State is not restored after process termination.

buildPlatformPage returns Flutter SDK MaterialPage on Android and CupertinoPage on iOS as in the guide.
Only transitions differ; widgets, AppTheme.main(), colors, and text remain standard Flutter Material.
External material_ui/cupertino_ui packages are not reintroduced.
Thin context.pushTo/goTo wrappers delegate to generated push/go without route type checks.
main_shell_feature does not import other features and receives callbacks from router.
Other feature DI remains registered in common in data → domain → ui order.

Generate after route changes from packages/router:

~~~sh
fvm dart run build_runner build --force-jit
~~~

Manual check: splash → first tab → Open details → second tab → Open details → first tab
(its details remain open) → Back → second tab (its details remain open) → Back.
Back from a tab root must not reopen splash. Mobile tests also verify language changes
without losing either stack.

Theme, localization, and initialization from PR #14–16 are already merged into develop.
Navigation changes must be integrated after prerequisite PRs and another check against the current develop.

## Mobile shell and startup

main.dart only selects EnvironmentType and calls the asynchronous run in main_common.dart.
Debug semantics is enabled once for the app lifetime; release builds do not make this call.
Localization is initialized before portraitUp, and the platform orientation request must complete
before DI registration. MainDependenciesModuleResolver.register is currently synchronous;
if it becomes asynchronous, await its Future before ApplicationInitializer.

run awaits the initializer before creating the App tree. Successful initialization marks StartupStatus ready;
splash checks that state and uses go to open the tabs without repeating initialization.
The existing initialization recovery path remains: splash retries only when startup is not ready
and shows an explicit retry button on failure.
AppThemeProvider wraps MaterialApp.router; one router lives until App is disposed.
Current localizationDelegates/supportedLocales/locale update the UI without creating a new router.

Only ApplicationInitializer installs FlutterError.onError and PlatformDispatcher.onError;
main_common does not create duplicate handlers. CrashReportingService receives original error/stackTrace;
the local writer records a safe error type, stack, and fatal. No external crash SDK is connected.
For a manual debug check, temporarily call FlutterError.reportError or trigger an unhandled async error,
check tricount.errors, and remove the trigger before committing. VM service checks need no source changes.

Manual Android/iOS checklist:

1. Run the dev flavor: initial preparation completes before splash → tabs.
2. Verify portrait orientation and uk/en through the localization context.
3. Trigger intentional framework/async errors and verify error/stack/fatal in tricount.errors.
4. Ensure no error triggers remain in source files after the check.

iOS native launch requires macOS/Xcode; an iOS-platform widget test does not replace it.
Flutter may ignore orientation lock for iPad multitasking and Android 16 large displays;
this stage does not change multitasking configuration.

## Network client: core

DioClient implements ApiClient for future data/source services. Public core.dart exports both types,
DioClientConfiguration, ApiError/ApiErrorKind, and the required CancelToken/Interceptor/InterceptorsWrapper.
Dio was already present in core and the root pubspec; this stage does not change its version or lockfile.

Pass configuration to the constructor, CoreDependenciesModuleResolver.register,
or MainDependenciesModuleResolver.register through dioConfiguration:
baseUrl, connectTimeout (15 s), sendTimeout (30 s), receiveTimeout (30 s), and headers.
Timeouts must be positive; a nonempty baseUrl must be an absolute HTTP(S) URL.
The client copies the header map; per-request headers do not change subsequent requests' settings.
The backend URL is not defined yet: default baseUrl is empty and startup makes no requests.
A relative request without a base URL returns Left with kind configuration without transport;
an absolute HTTP(S) URL can be provided explicitly. No real endpoints or business services were added.

Available methods: get/post/put/patch/delete/head and request with method, data, queryParameters,
headers, cancelToken, and required decode(Object?). The result is Future<Either<ApiError,T>>.
ApiError extends Failure, allowing repositories to map transport errors to scenario-specific failures.
Right contains the decoder result; Left contains a safe kind and statusCode when available.
ApiError includes no response body, URL, headers, or exception message.
HTTP errors do not reach the decoder; JSON/decoder errors use kind decoding.
Network, timeout, certificate, HTTP, cancellation, and unknown failures are distinguished.
There are no automatic retries, authentication, refresh tokens, or hidden write retries.

Supply interceptors to the constructor or add them with addInterceptor.
Transport and decoder errors are forwarded to the existing CrashReportingService with original error/stackTrace.
The local writer records only a safe type, stack, and fatal, without request/response payloads, URLs, or headers.
Cancellation is not recorded as a crash. Reporter failure does not turn Either into an unhandled exception.
LogInterceptor is not added automatically; new interceptors must not log secrets or financial data.

Core DI registers one lazy DioClient and an ApiClient alias to the same instance.
await DependencyProvider.reset() closes an instantiated client through close(force: true);
reset does not instantiate an unused client. close is idempotent; subsequent requests return kind closed.
Owners must close clients they create themselves. ApiClientImpl(dio: ...) remains a compatible constructor
for the previous API; new code should use DioClientConfiguration and injected CrashReportingService.
