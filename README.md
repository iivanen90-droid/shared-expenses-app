# Tricount — Спільні витрати

Flutter-застосунок для Android/iOS. Реалізована базова оболонка: splash із перевіркою
готовності та повтором після помилки, стартовий екран, дві вкладки з незалежними стеками,
українська/англійська локалізація.
Облік витрат, групи, баланси та синхронізація ще не реалізовані.

## Структура

Dart workspace: `mobile/`, `packages/{core,ui_kit,common,router}/`,
`features/{splash_feature,home_feature,main_shell_feature}/`. Залежності узгоджуються одним root `pubspec.lock`.
[Поточна архітектура](docs/architecture.md) пояснює пакети, шари, залежності та додавання фіч.
[Довідник Inspiro](docs/inspiro-architecture-guide.md) — джерело рішень;
[план Tricount](docs/tricount-architecture.md) — майбутні продуктові модулі.

## Інструменти та залежності

- Flutter **3.47.7** / Dart **3.13.5**, точна версія для всіх розробників; команди нижче використовують FVM.
- Android SDK і JDK для Android; macOS/Xcode для iOS.
- Ключі, локальні шляхи SDK та приватні envs не комітяться.

```sh
fvm use 3.47.7
fvm flutter pub get
```

Якщо `fvm` ще не встановлено, скористайтеся [інструкцією FVM](https://fvm.app/documentation/getting-started/installation).
Після встановлення executable FVM має бути доступний у `PATH` термінала.
`.fvmrc` і `.fvm/` локальні та ігноруються Git. Після кожного нового клонування
виконайте `fvm use 3.47.7` з кореня: це створить локальний `.fvmrc` для потрібної версії.
На Windows без прав створення symlink перед цією командою створіть у корені локальний `.fvmrc`:

```json
{
  "flutter": "3.47.7",
  "privilegedAccess": false,
  "updateVscodeSettings": false
}
```

У цьому режимі CLI працює без символічних посилань; SDK в IDE обирається вручну.
Не додавайте локальний `.fvmrc` у Git примусово.
Не використовуйте `fvm global`: версія обирається лише для цього репозиторію.

## Учасники workspace та залежності

Workspace member — пакет із власним `pubspec.yaml`, зареєстрований у `workspace:` кореневого
`pubspec.yaml`. Усі учасники використовують один набір версій, кореневі `pubspec.lock` і
`.dart_tool/package_config.json`. Dart workspaces підтримуються починаючи з Dart 3.6;
зафіксована для проєкту версія Dart 3.13.5 підходить.

| Каталог | `name` пакета |
|---|---|
| `packages/core/` | `core` |
| `packages/ui_kit/` | `ui_kit` |
| `packages/common/` | `common` |
| `packages/router/` | `router` |
| `mobile/` | `mobile` |
| `features/splash_feature/` | `splash_feature` |
| `features/home_feature/` | `home_feature` |
| `features/main_shell_feature/` | `main_shell_feature` |

Кожен учасник має `resolution: workspace` і `publish_to: 'none'`. Версії зовнішніх залежностей
обмежуються в кореневому `pubspec.yaml`, учасники перелічують потрібні пакети без версій.
Обмеження кореня беруть участь у спільному розв'язанні залежностей; точні версії записані у lockfile.
Внутрішні пакети автоматично беруться з workspace за `name`, без `path:` чи `dependency_overrides`.
Окремих overrides або Melos для поточної структури не потрібно.
Не запускайте незалежний `pub get` зі скинутим workspace і не комітьте lockfile у підпакетах.
Звичайний `pub get` з каталогу учасника також використовує кореневий workspace.

Перевірити зареєстровані пакети з кореня:

```sh
fvm dart pub workspace list
```

### Додавання feature-пакета

Приклад нижче — шаблон для майбутньої погодженої функції, а не вже створений пакет.

1. Створіть `features/example_feature/lib/example_feature.dart` і `features/example_feature/pubspec.yaml`:

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

2. Додайте `  - features/example_feature` до списку `workspace:` у кореневому `pubspec.yaml`.
   Назва пакета має бути унікальною. Версію нової зовнішньої залежності задайте в корені,
   а в пакеті додайте її без версії.
3. У пакеті-споживачі додайте залежність `example_feature:` й імпортуйте публічний barrel:
   `package:example_feature/example_feature.dart`. Саме членство у workspace не замінює залежність.
4. Додайте потрібні data/domain/ui, тести й DI за [архітектурною інструкцією](docs/architecture.md#нова-фіча).
   Якщо фіча містить екран, зареєструйте його DI у common та маршрут у router.
5. З кореня виконайте `fvm flutter pub get`, `fvm dart pub workspace list` та
   `fvm dart tools/workspace.dart check`. Для фіч із codegen перед перевіркою виконайте
   `fvm dart tools/workspace.dart generate`. Комітьте зміни кореневого lockfile разом із pubspec-файлами.

## Базова тема

Застосунок використовує стандартний Flutter Material і одну тему `AppTheme.main()` із ui_kit.
Кольори доступні через `context.colors`, текстові стилі — через `context.texts`.
Використовується стандартний шрифт Flutter, власні font assets не підключені.
За новим етапом прямі material_ui/cupertino_ui залежності прибрано; ці пакети ще присутні
транзитивно через go_router. Деталі — в [архітектурній документації](docs/architecture.md#базова-тема-ui_kit).

## Запуск

З кореня перейдіть у `mobile/`:

```sh
cd mobile
fvm flutter run --flavor dev --dart-define-from-file=../envs/dev.example.json
```

Для prod використовуйте `--flavor prod --dart-define-from-file=../envs/prod.example.json`.
Безпечні приклади працюють без секретів; власні файли `envs/*.json` ігноруються Git.
ENVIRONMENT має збігатися з native flavor. Dev має окремий id із `.dev`.
Android productFlavors та iOS shared schemes налаштовані; iOS збирається тільки на macOS/Xcode.
Production signing, сервер та публікація в магазинах не налаштовані.

## Аналізатор і форматування

Усі workspace-пакети й `mobile` успадковують кореневий `analysis_options.yaml` через пошук
у батьківських каталогах. Не створюйте окремі правила в підпакетах без потреби;
якщо локальний файл потрібний, він має явно включати кореневий через `include`.
Основа — `flutter_lints`, увімкнені `strict-casts` і `strict-raw-types`, `formatter.page_width: 120`.

| Рівень | Правила з архітектурного довідника |
|---|---|
| `error` | `unused_import`, `missing_required_param`, `must_be_immutable`, `missing_enum_constant_in_switch`, `sort_child_properties_last`, `missing_dependency`, `invalid_dependency` |
| `warning` | `always_use_package_imports`, `prefer_const_constructors`, `require_trailing_commas`, `prefer_final_locals`, `avoid_print` |

Згенеровані `*.g.dart`, `*.freezed.dart`, `generated/` та build-каталоги виключені з аналізу.
`check` вважає невдалими і warnings, і infos. Форматування вихідного коду:

```sh
fvm dart tools/workspace.dart format
fvm dart tools/workspace.dart check
```

Кореневий `build.yaml` задає Freezed `line_length: 120`; такі ж локальні налаштування є у
feature-пакетах, звідки запускається генератор. У Freezed 3.2.5 `line_length` сам по собі
не задає ширину DartFormatter: `format: true` прибирає заборону `dart format off`, а фінальний
`dart format` у workspace-команді застосовує спільну ширину 120 до згенерованого коду.
Локальні SDK, build/cache-каталоги та налаштування IDE виключені через `.gitignore`.

## Локалізація en / uk

`packages/common/lib/src/localization/langs/en.json` та `uk.json` містять однакові ключі.
Шлях зареєстрований у assets пакета common, wrapper використовує пакетний префікс
`packages/common/lib/src/localization/langs`. `common.dart` експортує LocalizationsWrapper,
AppLocalizationContext та згенеровані LocaleKeys.

Після `WidgetsFlutterBinding.ensureInitialized()` mobile викликає
`await EasyLocalization.ensureInitialized()`, а потім обгортає App у LocalizationsWrapper.
Збережена мова має пріоритет; без неї обирається підтримувана системна мова.
Для непідтримуваної мови та відсутнього перекладу використовується англійська (`en`).
MaterialApp отримує delegates, supportedLocales та поточний `context.locale`, тому
`await context.setLocale(const Locale('uk'))` або Locale('en') оновлює інтерфейс і зберігає вибір.
Окремого екрана вибору мови поки немає.

Щоб додати переклад, додайте той самий ключ і непорожній текст до обох JSON, потім з кореня
запустіть `bash tools/tr_keys_gen.sh` (на Windows — у Git Bash). Джерело генерації — en.json;
`locale_keys.g.dart` не редагується вручну. Без Bash виконайте з packages/common/:

```sh
fvm dart run easy_localization:generate -S lib/src/localization/langs -s en.json -O lib/src/localization -f keys -o locale_keys.g.dart
fvm dart format lib/src/localization/locale_keys.g.dart
```

У UI використовуйте `LocaleKeys.someKey.tr(context: context)`, а не текст чи ключі вручну.
Після зміни перекладів виконайте `fvm dart tools/workspace.dart check` з кореня.
Перевірки common звіряють JSON-ключі, відновлення мови, оновлення UI та англійський fallback.

## Генерація

```sh
fvm dart tools/workspace.dart generate
```

Скрипт генерує LocaleKeys у common, assets у ui_kit, типізовані routes у router та freezed-стани
у фічах, потім форматує код. Кожен build_runner запускається з пакета-власника.
JIT-режим не залежить від AOT-компіляції генераторів у тимчасовому каталозі Windows.
Згенеровані `*.g.dart`, `*.freezed.dart` та `assets.gen.dart` зберігаються в Git і не редагуються вручну.
Окремий пакет: `fvm dart run build_runner build --force-jit` у його каталозі.
Для ключів та assets є також `tools/tr_keys_gen.sh` і `tools/flutter_gen.sh`.

## Перевірки

```sh
fvm dart tools/workspace.dart check
```

Виконує `pub get --enforce-lockfile`, перевірку форматування, строгий аналіз усього workspace
та тести в кожному пакеті, де є `test/`. Root не містить Flutter-тестів.
Окремі команди: `format`, `analyze`, `test`, `get`, `generate` замість `check`.
Наприклад, з `features/splash_feature/` можна виконати `fvm flutter test`.
Якщо SDK уже встановлений без FVM, локально задайте `TRICOUNT_FLUTTER_SDK` і запускайте
`dart tools/workspace.dart check`; шлях не записується у файли репозиторію.

Android dev-збірка з `mobile/`:

```sh
fvm flutter build apk --debug --flavor dev --dart-define-from-file=../envs/dev.example.json
```

Maestro після встановлення dev-застосунку: `maestro test .maestro/startup.yaml` з кореня.
Сценарій використовує Semantics identifier `home_title`. Наявність сценарію не означає,
що його запущено на пристрої. Flutter CI не увімкнено; його повернення — окрема задача.

### Codex code review


Окремо увімкни автоматичний code review для цього репозиторію в налаштуваннях
Codex і вибери тригер перевірки після кожного push у pull request.
`AGENTS.md` задає правила перевірки, але сам не вмикає цей перемикач.
Якщо налаштування не збереглися, онови сторінку й перевір їх повторно.
У підключеному репозиторії review також можна запросити коментарем `@codex review`
у pull request. Звичайний push без pull request не є запитом Codex review.

Workflow `.github/workflows/codex-review.yml` автоматично додає коментар
`@codex review` після відкриття PR у `develop` або `main`, повторного відкриття, нового push
або переведення чернетки в готовий до перевірки PR. Новий автоматичний запуск
скасовує попередній автоматичний запуск для цього PR. Ручні повтори мають
окрему групу для кожного SHA: повтор старого коміту не скасовує автоматичний
запуск або ручний повтор нового коміту. Перед публікацією перевіряється
актуальність коміту.
Звичайні події для того самого коміту не дублюють коментар. Якщо Codex не
прийняв запит, відкрий **Actions → Request Codex review → потрібний запуск →
Re-run jobs → Re-run all jobs** або повторно відкрий PR: ці явні повторні
спроби додають новий запит навіть за наявності старого маркера. Перезапуск
застарілого коміту, закритого PR або чернетки не публікує коментар.
Чернетки, PR із форків і PR Dependabot
пропускаються; для них запит можна залишити вручну після підготовки PR.
Workflow використовує стандартний `GITHUB_TOKEN` із правом `pull-requests: write`
і не потребує `OPENAI_API_KEY`. Політика репозиторію має дозволяти це право.
Для виконання запиту репозиторій має бути підключений до Codex і мати
опубліковане хмарне середовище. Якщо бот просить створити середовище,
заверши його налаштування й повтори запит після публікації.
Коментар є запитом на review: фактичний запуск потрібно підтвердити реакцією
Codex 👀 та результатом перевірки. Сам факт публікації коментаря від
`github-actions[bot]` не підтверджує, що Codex прийняв запит.

Перевірка сценаріїв workflow (потрібен Node.js 22 або новіший):

```sh
node --test .github/tests/codex-review.test.cjs
```

Офіційна інструкція: [Codex review у GitHub](https://developers.openai.com/codex/integrations/github).


## Порядок внесення змін

`develop` — основна й захищена гілка. Кожна задача — окрема гілка від актуального
`origin/develop`, PR із base `develop`, code review й одне незалежне схвалення.
Прямі push, force push, видалення develop і обхід захисту адміністраторами заборонені.
Правила агента — [AGENTS.md](AGENTS.md), порядок розробки — [CLAUDE.md](CLAUDE.md).

Старт застосунку: Flutter binding → реєстрація core і фіч у DI →
await ApplicationInitializer.initialize() (обробники помилок і готовність запуску) →
локалізація → runApp. При помилці ініціалізації доступне відновлення через splash.
Нові Cubit успадковують SafeCubitWrapper, який ігнорує emit після close.
Порядок підключення нової фічі та життєвий цикл обробників описані в
[архітектурі](docs/architecture.md).

## Навігація вкладок

Після ініціалізації /splash замінюється на /home. Дві вкладки зберігають незалежні
стеки через типізований StatefulShellRoute; друга вкладка — порожня оболонка.
«Відкрити деталі» в кожній вкладці веде на порожню вкладену сторінку для перевірки
push/Back і збереження стеків. Фінансової логіки в цих сторінках немає.
Тема та en/uk локалізація застосовуються до обох вкладок.
Матеріальні віджети використовують MaterialPage на Android і SDK CupertinoPage на iOS.

Після зміни routes з packages/router виконайте:

~~~sh
fvm dart run build_runner build --force-jit
~~~

Ручний сценарій перемикання й Back — у [документації навігації](docs/architecture.md#оболонка-вкладок-і-маршрути).
