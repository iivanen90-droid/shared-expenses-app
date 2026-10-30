# Tricount — Shared expenses

Flutter application for Android/iOS. The implemented shell includes splash with readiness checks
and retry after failure, a home screen, two tabs with independent stacks, and Ukrainian/English localization.
Expense tracking, groups, balances, and synchronization are not implemented yet.

## Structure

Dart workspace: `mobile/`, `packages/{core,ui_kit,common,router}/`,
`features/{splash_feature,home_feature,main_shell_feature}/`. Dependencies share one root `pubspec.lock`.
The [current architecture](docs/architecture.md) explains packages, layers, dependencies, and adding features.
The [Inspiro guide](docs/inspiro-architecture-guide.md) is the source reference;
the [Tricount roadmap](docs/tricount-architecture.md) describes future product modules.

## Tools and dependencies

- Flutter **3.47.7** / Dart **3.13.5**, pinned for every developer; the commands below use FVM.
- Android SDK and JDK for Android; macOS/Xcode for iOS.
- Do not commit keys, local SDK paths, or private environments.

```sh
fvm use 3.47.7
fvm flutter pub get
```

If `fvm` is not installed, follow the [FVM installation guide](https://fvm.app/documentation/getting-started/installation).
Make its executable available in the terminal's `PATH`.
`.fvmrc` and `.fvm/` are local and ignored by Git. After every fresh clone,
run `fvm use 3.47.7` from the root to create the local `.fvmrc` for the required version.
On Windows without symlink creation privileges, first create this local root `.fvmrc`:

```json
{
  "flutter": "3.47.7",
  "privilegedAccess": false,
  "updateVscodeSettings": false
}
```

This mode runs the CLI without symbolic links; select the SDK manually in the IDE.
Do not force-add the local `.fvmrc` to Git or use `fvm global`: select the version only for this repository.

## Workspace members and dependencies

A workspace member is a package with its own `pubspec.yaml`, registered under `workspace:` in the root
`pubspec.yaml`. All members share one set of versions, the root `pubspec.lock`, and
`.dart_tool/package_config.json`. Dart workspaces require Dart 3.6 or later;
the pinned Dart 3.13.5 version satisfies this requirement.

| Directory | Package `name` |
|---|---|
| `packages/core/` | `core` |
| `packages/ui_kit/` | `ui_kit` |
| `packages/common/` | `common` |
| `packages/router/` | `router` |
| `mobile/` | `mobile` |
| `features/splash_feature/` | `splash_feature` |
| `features/home_feature/` | `home_feature` |
| `features/main_shell_feature/` | `main_shell_feature` |

Each member declares `resolution: workspace` and `publish_to: 'none'`. The root `pubspec.yaml`
constrains external dependency versions; members list the packages they need without versions.
Root constraints participate in the shared resolution; the lockfile records exact versions.
Internal packages resolve from the workspace by `name`, without `path:` or `dependency_overrides`.
The current structure needs neither extra overrides nor Melos.
Do not run an independent `pub get` with workspace resolution disabled or commit lockfiles in subpackages.
A normal `pub get` from a member directory also uses the root workspace.

List registered packages from the root:

```sh
fvm dart pub workspace list
```

### Adding a feature package

The following example is a template for a future agreed feature, not an existing package.

1. Create `features/example_feature/lib/example_feature.dart` and `features/example_feature/pubspec.yaml`:

```yaml
name: example_feature
publish_to: 'none'
environment:
  sdk: ^3.13.5
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  core:
```

2. Add `  - features/example_feature` to the root `workspace:` list. The name must be unique.
   Set any new external dependency's version at the root and list it without a version in the member.
3. Add `example_feature:` as a consumer dependency and import its public barrel:
   `package:example_feature/example_feature.dart`. Workspace membership does not replace a dependency declaration.
4. Add data/domain/ui, tests, and DI following the [architecture instructions](docs/architecture.md#adding-a-feature).
   For a screen feature, register its DI in common and route in router.
5. From the root, run `fvm flutter pub get`, `fvm dart pub workspace list`, and
   `fvm dart tools/workspace.dart check`. For features with codegen, first run
   `fvm dart tools/workspace.dart generate`. Commit root lockfile changes with the pubspec files.

## Base theme

The application uses standard Flutter Material and one `AppTheme.main()` from ui_kit.
Access colors through `context.colors` and text styles through `context.texts`.
Flutter's default font is used; no custom font assets are included.
The base-theme stage removed direct material_ui/cupertino_ui dependencies; those packages remain
transitive dependencies of go_router. See the [architecture documentation](docs/architecture.md#base-theme-ui_kit).

## Running the application

From the root, enter `mobile/`:

```sh
cd mobile
fvm flutter run --flavor dev --dart-define-from-file=../envs/dev.example.json
```

For prod, use `--flavor prod --dart-define-from-file=../envs/prod.example.json`.
Safe examples work without secrets; custom `envs/*.json` files are ignored by Git.
ENVIRONMENT must match the native flavor. Dev uses a separate ID with the `.dev` suffix.
Android productFlavors and iOS shared schemes are configured; iOS builds require macOS/Xcode.
Production signing, a backend, and store publishing are not configured.

## Analyzer and formatting

All workspace packages and `mobile` inherit the root `analysis_options.yaml` through parent-directory lookup.
Do not create separate subpackage rules without a need; any necessary local file must explicitly
include the root configuration through `include`.
The configuration uses `flutter_lints`, `strict-casts`, `strict-raw-types`, and `formatter.page_width: 120`.

| Severity | Rules from the architecture guide |
|---|---|
| `error` | `unused_import`, `missing_required_param`, `must_be_immutable`, `missing_enum_constant_in_switch`, `sort_child_properties_last`, `missing_dependency`, `invalid_dependency` |
| `warning` | `always_use_package_imports`, `prefer_const_constructors`, `require_trailing_commas`, `prefer_final_locals`, `avoid_print` |

Generated `*.g.dart`, `*.freezed.dart`, `generated/`, and build directories are excluded from analysis.
`check` fails on both warnings and infos. Format and check source code with:

```sh
fvm dart tools/workspace.dart format
fvm dart tools/workspace.dart check
```

The root `build.yaml` sets Freezed `line_length: 120`; feature packages that run the generator
have matching local configuration. In Freezed 3.2.5, `line_length` alone does not set DartFormatter's width:
`format: true` removes the `dart format off` restriction; the workspace command's final
`dart format` applies the shared width of 120 to generated code.
Local SDKs, build/cache directories, and IDE settings are excluded through `.gitignore`.

## Localization: en / uk

`packages/common/lib/src/localization/langs/en.json` and `uk.json` contain the same keys.
The path is registered in common's assets; the wrapper uses the package prefix
`packages/common/lib/src/localization/langs`. `common.dart` exports LocalizationsWrapper,
AppLocalizationContext, and generated LocaleKeys.

After `WidgetsFlutterBinding.ensureInitialized()`, mobile calls
`await EasyLocalization.ensureInitialized()` and wraps App in LocalizationsWrapper.
A saved language takes precedence; otherwise, a supported system language is selected.
English (`en`) is the fallback for unsupported languages and missing translations.
MaterialApp receives delegates, supportedLocales, and the current `context.locale`, so
`await context.setLocale(const Locale('uk'))` or Locale('en') updates the UI and saves the selection.
There is no language-selection screen yet.

Add each new key with nonempty text to both JSON files, then run `bash tools/tr_keys_gen.sh`
from the root (Git Bash on Windows). en.json is the generation source; never edit `locale_keys.g.dart` manually.
Without Bash, run from packages/common/:

```sh
fvm dart run easy_localization:generate -S lib/src/localization/langs -s en.json -O lib/src/localization -f keys -o locale_keys.g.dart
fvm dart format lib/src/localization/locale_keys.g.dart
```

Use `LocaleKeys.someKey.tr(context: context)` in UI instead of literal text or manually entered keys.
After translation changes, run `fvm dart tools/workspace.dart check` from the root.
Common tests verify matching JSON keys, language restoration, UI updates, and English fallback.

## Generation

```sh
fvm dart tools/workspace.dart generate
```

The script generates LocaleKeys in common, assets in ui_kit, typed routes in router, and freezed states
in features, then formats code. Each build_runner runs from its owning package.
JIT mode avoids reliance on AOT generator compilation in Windows temporary directories.
Generated `*.g.dart`, `*.freezed.dart`, and `assets.gen.dart` files are committed and never edited manually.
For one package, run `fvm dart run build_runner build --force-jit` in its directory.
`tools/tr_keys_gen.sh` and `tools/flutter_gen.sh` are also available for keys and assets.

## Verification

```sh
fvm dart tools/workspace.dart check
```

Runs `pub get --enforce-lockfile`, formatting checks, strict analysis of the entire workspace,
and tests in each package with a `test/` directory. The root contains no Flutter tests.
Individual commands: replace `check` with `format`, `analyze`, `test`, `get`, or `generate`.
For example, run `fvm flutter test` from `features/splash_feature/`.
If the SDK is installed without FVM, set `TRICOUNT_FLUTTER_SDK` locally and run
`dart tools/workspace.dart check`; the path is not written to repository files.

Android dev build from `mobile/`:

```sh
fvm flutter build apk --debug --flavor dev --dart-define-from-file=../envs/dev.example.json
```

After installing the dev app, run `maestro test .maestro/startup.yaml` from the root.
The scenario uses the Semantics identifier `home_title`. A scenario's presence does not mean
it has been run on a device. Flutter CI is disabled; restoring it is a separate task.

### Codex code review

Enable automatic code review for this repository in Codex settings separately and select
the trigger to review after each push to a pull request.
`AGENTS.md` defines review rules but does not enable that setting.
If settings did not persist, refresh the page and check again.
In a connected repository, request review with the PR comment `@codex review`.
A push without a pull request is not a Codex review request.

The `.github/workflows/codex-review.yml` workflow automatically posts `@codex review` when a PR
targeting `develop` or `main` is opened, reopened, updated by a push, or marked ready for review.
A new automatic run cancels the previous automatic run for that PR. Manual reruns have separate
concurrency groups per SHA: rerunning an old commit does not cancel an automatic run or a manual rerun
for a newer commit. The workflow checks that the commit is current before posting.
Normal events for the same commit do not duplicate comments. If Codex did not accept the request,
open **Actions → Request Codex review → the relevant run → Re-run jobs → Re-run all jobs**, or reopen
the PR. These explicit retries post a new request even when an old marker exists.
Rerunning an outdated commit, closed PR, or draft does not post a comment.
Drafts, fork PRs, and Dependabot PRs are skipped; request review manually when they are ready.
The workflow uses standard `GITHUB_TOKEN` with `pull-requests: write` and needs no `OPENAI_API_KEY`.
Repository policy must allow that permission.
The repository must be connected to Codex with a published cloud environment for review to run.
If the bot requests an environment, finish setup and retry after publishing it.
A comment is a review request: confirm actual execution through Codex's 👀 reaction and review result.
A comment posted by `github-actions[bot]` alone does not confirm that Codex accepted the request.

Workflow scenario tests require Node.js 22 or later:

```sh
node --test .github/tests/codex-review.test.cjs
```

Official instructions: [Codex review on GitHub](https://developers.openai.com/codex/integrations/github).

## Change workflow

`develop` is the default protected branch. Each task uses a separate branch from current
`origin/develop`, a PR targeting `develop`, code review, and one independent approval.
Direct pushes, force pushes, deleting develop, and administrator bypass are prohibited.
Agent rules are in [AGENTS.md](AGENTS.md); the development workflow is in [CLAUDE.md](CLAUDE.md).

Application startup: Flutter binding → debug semantics → localization → await portraitUp →
register core and feature DI → await ApplicationInitializer.initialize() (error handlers and startup readiness) → runApp.
Splash retains recovery after initialization failure. New Cubits extend SafeCubitWrapper,
which ignores emit after close. Feature registration and error-handler lifecycle are documented
in the [architecture](docs/architecture.md).

## Tab navigation

After initialization, /splash is replaced by /home. A typed StatefulShellRoute preserves independent
stacks for two tabs; the second tab is a placeholder shell.
Each tab's Open details button opens a placeholder nested page to verify push/Back and stack preservation.
These pages have no financial logic. The theme and en/uk localization apply to both tabs.
Material widgets use MaterialPage on Android and SDK CupertinoPage on iOS.

After route changes, run from packages/router:

~~~sh
fvm dart run build_runner build --force-jit
~~~

The manual switching/Back scenario is in the [navigation documentation](docs/architecture.md#tab-shell-and-routes).

The mobile shell awaits localization and portraitUp before DI, then awaits the initializer before runApp.
Only ApplicationInitializer installs global error handlers. Successful startup does not repeat on splash.
The manual launch and local error-log checklist is in the
[architecture](docs/architecture.md#mobile-shell-and-startup).

## Future API requests

Core provides DioClient with GET/POST/PUT/PATCH/DELETE/HEAD, configurable baseUrl, timeouts, and headers.
Pass configuration through dioConfiguration to MainDependenciesModuleResolver.register.
ApiClient and DioClient in DI refer to the same lazy singleton. The result is Either<ApiError,T>,
where ApiError is a Failure. The supplied decode transforms data; each feature will define its business failures.

No server URL or endpoints are configured; the app makes no API requests at startup.
Network tests use a fake HttpClientAdapter without Internet requests.
Configuration, interceptors, logging, and cleanup are described in the
[client documentation](docs/architecture.md#network-client-core).
