# Tricount — Спільні витрати

Flutter-застосунок для Android/iOS. Реалізована базова оболонка: splash із перевіркою
готовності та повтором після помилки, стартовий екран, українська/англійська локалізація.
Облік витрат, групи, баланси та синхронізація ще не реалізовані.

## Структура

Dart workspace: `mobile/`, `packages/{core,ui_kit,common,router}/`,
`features/{splash_feature,home_feature}/`. Залежності узгоджуються одним root `pubspec.lock`.
[Поточна архітектура](docs/architecture.md) пояснює пакети, шари, залежності та додавання фіч.
[Довідник Inspiro](docs/inspiro-architecture-guide.md) — джерело рішень;
[план Tricount](docs/tricount-architecture.md) — майбутні продуктові модулі.

## Інструменти та залежності

- Flutter **3.47.7** / Dart **3.13.5**, версія у `.fvmrc`; команди нижче використовують FVM.
- Android SDK і JDK для Android; macOS/Xcode для iOS.
- Ключі, локальні шляхи SDK та приватні envs не комітяться.

```sh
fvm use 3.47.7
fvm flutter pub get
```

Учасники workspace мають `resolution: workspace`; версії пакетів задаються в root `pubspec.yaml`.
Не запускати незалежний `pub get` зі скинутим workspace і не комітити lockfile у підпакетах.

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
