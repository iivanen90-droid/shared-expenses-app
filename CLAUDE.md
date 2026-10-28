# Порядок роботи над Tricount

Основні правила — [AGENTS.md](AGENTS.md), команди — [README.md](README.md).
[Поточна архітектура](docs/architecture.md), [джерело Inspiro](docs/inspiro-architecture-guide.md),
[майбутні модулі Tricount](docs/tricount-architecture.md).

## Архітектурні правила

- Workspace реалізований: mobile, core, ui_kit, common, router, splash_feature, home_feature, main_shell_feature.
  Фінансових функцій ще немає. Не переносити редактор, покупки чи інтеграції Inspiro.
- Core та ui_kit — незалежні від інших пакетів workspace. Фіча не імпортує іншу фічу.
  Доступ до чужих пакетів лише через публічний barrel, не через `src/`.
- Page → Cubit → Interactor → Repository → Source. Source/Repository/Interactor — interface + Impl.
  Constructor injection — required named параметри, поля приватні. Cubit не викликає repository.
- Cubit успадковує SafeCubitWrapper. Один freezed-state зі status enum. Page створює Cubit через DI.
- Bootstrap: binding → debug semantics → await локалізація → await portraitUp → DI → await ApplicationInitializer → runApp.
  Глобальні обробники встановлює лише initializer; успішний startup не повторюється на splash.
- Три DI-resolver кожної фічі реєструються в common після core у порядку data → domain → ui.
- Routes типізовані в router. Початок — splash; buildPlatformPage використовує SDK MaterialPage / CupertinoPage за платформою.
  StatefulShellRoute вже містить дві вкладки з окремими стеками. Не додавати бізнес-екрани поза завданням.
- UI — стандартний `package:flutter/material.dart`; тема — AppThemeProvider і context.colors/texts/icons.
  За новим етапом material_ui, cupertino_ui не використовуються; CupertinoPage задає лише iOS-перехід для Material-віджетів.
  Стандартний шрифт Flutter, без font assets. Рядки — LocaleKeys, easy_localization; assets — flutter_gen.
- Either<Failure,T>, обробка винятків у data/domain. DTO/json_serializable та ObjectBox додаються,
  коли є погоджений API чи структуровані дані. Не додавати порожні мережеві/БД сценарії.
- Аналітика через клас екрана з Cubit; жодних фінансових/персональних payload і повідомлень винятків у логах.
- Імпорти `package:`, без widget-функцій, вкладених ternary, неперевірених `!` і context після await без mounted.
- Генеровані файли не редагувати вручну. Спільний `pubspec.lock` залишається в Git.
  `.fvmrc` локальний та ігнорується; версія Flutter й налаштування після клонування — у README.

## Нова функціональність

Погодити екран, поведінку, дані та обсяг. Додати пакет, layers/index/barrel і короткий CLAUDE.md;
оновити workspace та залежності common/router. Реалізувати DI, interactor, Cubit, typed route,
локалізацію, тему та Semantics identifiers. Додати тести interactor/Cubit і widget-тест сторінки.
Докладний порядок — у [docs/architecture.md](docs/architecture.md).

## Генерація й перевірки

```sh
fvm flutter pub get
fvm dart tools/workspace.dart generate
fvm dart tools/workspace.dart check
```

Якщо змінюються лише переклади, достатньо `bash tools/tr_keys_gen.sh` або команди без Bash із README.
Build_runner виконується з пакета-власника. Тести запускаються в кожному пакеті.
Команди dev/prod та Android build наведені в README. iOS потребує macOS/Xcode;
недоступні перевірки зазначати явно. Не комітити SDK paths, секрети, build або приватні envs.

## Гілки та review

Для кожної задачі — окрема гілка `codex/<name>` від актуального origin/develop та PR у develop.
Прямі push у main/develop заборонені; force push і видалення develop заборонені.
Перед злиттям — code review й одне незалежне схвалення; автор не схвалює свій PR.
Нові коміти скасовують схвалення. Codex review не замінює required approval.
Захист діє також для адміністраторів: не обходити й не послаблювати його.
Зберігати незакомічені зміни; за потреби працювати в окремому worktree.
Якщо тариф чи права не дозволяють захист, повідомити користувача та узгодити подальші дії.
