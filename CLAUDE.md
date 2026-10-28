# Порядок роботи над Tricount

Основні правила — [AGENTS.md](AGENTS.md), команди — [README.md](README.md).
[Поточна архітектура](docs/architecture.md), [джерело Inspiro](docs/inspiro-architecture-guide.md),
[майбутні модулі Tricount](docs/tricount-architecture.md).

## Архітектурні правила

- Workspace реалізований: mobile, core, ui_kit, common, router, splash_feature, home_feature.
  Фінансових функцій ще немає. Не переносити редактор, покупки чи інтеграції Inspiro.
- Core та ui_kit — незалежні від інших пакетів workspace. Фіча не імпортує іншу фічу.
  Доступ до чужих пакетів лише через публічний barrel, не через `src/`.
- Page → Cubit → Interactor → Repository → Source. Source/Repository/Interactor — interface + Impl.
  Constructor injection — required named параметри, поля приватні. Cubit не викликає repository.
- Cubit успадковує SafeCubitWrapper. Один freezed-state зі status enum. Page створює Cubit через DI.
- До runApp очікувати ApplicationInitializer.initialize(): обробники помилок і готовність preferences.
- Три DI-resolver кожної фічі реєструються в common після core у порядку data → domain → ui.
- Routes типізовані в router. Початок — splash; платформа визначає Material/Cupertino сторінку.
  StatefulShellRoute додавати, коли погоджені вкладки. Не вигадувати вкладки або бізнес-екрани.
- UI — material_ui/cupertino_ui; тема — AppThemeProvider і context.colors/texts/icons.
  Рядки — LocaleKeys, easy_localization; assets — flutter_gen. Імпорти Flutter SDK material/cupertino заборонені.
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
