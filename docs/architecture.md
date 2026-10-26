# Поточна архітектура Tricount

Основа — [довідник Inspiro](inspiro-architecture-guide.md). [Карта майбутніх модулів](tricount-architecture.md)
відокремлена від фактично реалізованої оболонки нижче.

## Що реалізовано

Dart workspace зі спільним `pubspec.lock`, версії залежностей — у кореневому `pubspec.yaml`.
Кожен учасник має `resolution: workspace`, `publish_to: 'none'` та власні `lib/`, `test/` за потреби.

| Шлях | Відповідальність |
|---|---|
| `mobile/` | Пакет `mobile`, Flutter-застосунок: точки входу, App, Android/iOS, dev/prod flavors, інтеграційні widget-тести |
| `packages/core/` | DI-фасад get_it, EnvironmentType, Failure, API та preferences обгортки, безпечна аналітика, готовність запуску |
| `packages/ui_kit/` | AppThemeProvider, context.colors/texts/icons, спільний індикатор, згенеровані SVG-assets |
| `packages/common/` | Збирання DI, ApplicationInitializer, SafeCubitWrapper, українська/англійська локалізація |
| `packages/router/` | Типізовані маршрути `/splash`, `/home`, сторінки Android/iOS, навігаційні розширення |
| `features/splash_feature/` | Перевірка готовності, loading/loaded/failed, повтор після помилки та перехід на home |
| `features/home_feature/` | Наявний стартовий екран, стан і подія відкриття; фінансових функцій немає |
| `envs/` | Безпечні dev/prod приклади; приватні конфігурації ігноруються Git |
| `tools/` | Команди workspace, codegen, локалізація, форматування, аналіз і тести |
| `.maestro/` | Сценарій перевірки стартового екрана на встановленому dev-застосунку |

## Залежності та потік

`core` й `ui_kit` не імпортують інші пакети workspace. `mobile` збирає common, router і ui_kit.
`common` реєструє DI фіч; router будує їхні сторінки. Фічі використовують публічні barrels common,
core, router, ui_kit. Зв'язки common ↔ feature ↔ router відповідають довіднику; чужий `src/` заборонений.
Прямі імпорти feature → feature заборонені. Спільні контракти надалі додаються в core.

Запуск: binding → EasyLocalization → DI (core, data → domain → ui) → App → splash → ApplicationInitializer. Помилка ініціалізації проходить через repository до стану splash; кнопка повтору знову виконує ініціалізацію.
Splash: `Page → Cubit → StartupInteractor → StartupRepository → StartupSource → StartupStatus`.
Результат — `Either<Failure, Unit>`; помилки перетворюються на Failure. Після успіху типізований маршрут
замінює splash на home. Сторінки самі створюють Cubit через BlocProvider і DependencyProvider.
SafeCubitWrapper ігнорує завершення async-операцій після закриття екрана.
Home поки не потребує repository/interactor; його data/domain-resolver не реєструють вигадані операції.

## Контракти core: DI та помилки

Публічний імпорт — `package:core/core.dart`. Він експортує `DependencyProvider`, абстрактний
`Failure` і типи `Either`, `Left`, `Right` із fpdart. Версії get_it/fpdart задаються в root
`pubspec.yaml`; core перелічує ці залежності без версій. Бізнес-правила й фічі до core не додаються.

`DependencyProvider` — статичний фасад над get_it:

| Метод | Контракт |
|---|---|
| `get<T>()` | Повертає зареєстрований сервіс типу T; відсутність реєстрації — помилка |
| `getOrNull<T>()` | Повертає null для незареєстрованого T; помилки створення зареєстрованого сервісу не приховує |
| `getWithParams<T>(param1: ..., param2: ...)` | Передає runtime-параметри фабриці; типи значень мають відповідати P1/P2 її реєстрації |
| `registerFactory<T>(factory)` | Новий екземпляр при кожному отриманні |
| `registerLazySingleton<T>(factory, dispose: ...)` | Один екземпляр, створюється при першому отриманні; необов'язковий dispose може бути синхронним або асинхронним |
| `registerFactoryWithParams<T, P1, P2>(factory)` | Типізована фабрика з двома runtime-параметрами |
| `isRegistered<T>()` | Перевіряє наявність реєстрації |
| `reset()` | Повертає `Future<void>`, очищає реєстрації та очікує dispose вже створених singleton-сервісів |

Завжди виконуйте `await DependencyProvider.reset()`; у тестах можна передати цей метод у
`tearDown`. Невикористаний lazy singleton не створюється лише заради очищення. Фабричні
екземпляри не зберігаються контейнером: їхній життєвий цикл завершує власник, наприклад BlocProvider.

Операції domain/data, які можуть завершитися очікуваною помилкою, повертають
`Either<Failure, T>` або `Future<Either<Failure, T>>`: `Left(failure)` — помилка,
`Right(value)` — успіх. Конкретні Failure визначаються в модулі відповідного сценарію;
винятки перетворюються на них на межі data/domain. Cubit обробляє обидві гілки через fold.
Базовий Failure не містить бізнес-логіки чи даних користувача.

## Локальні налаштування: PreferencesStorage

Споживачі отримують `PreferencesStorage` через `DependencyProvider.get<PreferencesStorage>()`
з публічного `core.dart`; реалізація `PreferencesStorageImpl` не експортується з barrel.
`CoreDependenciesModuleResolver` реєструє її як lazy singleton і викликається першим у
`MainDependenciesModuleResolver`. Він також збирає решту базових core-сервісів.

Обгортка використовує `SharedPreferencesAsync` без локального кешу. `readBool`, `readInt`,
`readString` повертають відповідно `Future<bool?>`, `Future<int?>`, `Future<String?>`;
відсутній ключ дає null. `writeBool`, `writeInt`, `writeString` та `remove` повертають
`Future<void>` і мають очікуватися через await. Remove видаляє лише вказаний ключ, без clear
усього сховища. Помилки платформи та невідповідність типу не приховуються: їх обробляє data/source
споживача й за потреби перетворює на Failure.

`WidgetsFlutterBinding.ensureInitialized()` викликається в mobile до реєстрації DI;
нативний Flutter-registrant підключає плагін. Async API не потребує попереднього
`SharedPreferences.getInstance()` чи окремого кешу: клієнт створюється при першому отриманні
сервісу, доступ до платформи виконується асинхронними методами. У тестах перед отриманням
сервісу встановлюється офіційний in-memory async backend; у production він не використовується.
`shared_preferences_platform_interface` — лише пряма test-залежність core з версією в root.

Сховище призначене для некритичних налаштувань, а не фінансових записів чи секретів.
Обгортка не додає бізнес-ключів, не логує ключі/значення та не змінює сховище локалізації
всередині easy_localization. Окремих налаштувань користувача в UI поки немає.

## UI, генерація та середовища

UI імпортується з material_ui / cupertino_ui. Стилі — через AppThemeProvider і context-розширення;
рядки — через згенеровані LocaleKeys та easy_localization. Українська — стартова й резервна мова,
англійська доступна через локалізаційний контекст. Екрану зміни мови ще немає.
Стани — один freezed-клас зі status enum. Routes — go_router_builder. Assets — flutter_gen.
Генеровані файли комітяться, вручну їх не змінюємо.

Android має productFlavors dev/prod, iOS — відповідні shared schemes і Debug/Profile/Release конфігурації.
Dev має окремий application/bundle id із суфіксом `.dev`. ENVIRONMENT із dart-define має збігатися
з native flavor. Приклади не містять секретів. Production-підпис і публікація в магазинах не налаштовані.
Аналітика в dev локально записує назву події та технічні properties; дані користувача передавати заборонено.
CrashReportingService локально записує тип помилки, стек і fatal, не повідомлення довільного винятку.

Мережевий клієнт і preferences — обгортки без активних серверних запитів чи фінансових даних.
ObjectBox, DTO/json_serializable, вкладки StatefulShellRoute та бізнес-модулі додаються з першим
погодженим сценарієм, коли є відповідні дані/API/вкладки. Це не реалізовані можливості оболонки.

## Аналітика та логування помилок

Публічний `core.dart` експортує лише `AnalyticsTracker`, `AnalyticsTrackerFactory` і
`CrashReportingService`. Реалізації зареєстровані в core DI. Фабрика створює трекер через
`create(screenName: ...)`; також доступний `getWithParams<AnalyticsTracker>(param1: screenName)`.
Трекер зберігає назву свого екрана, тому різні екрани не перезаписують контекст один одного.

`track(eventName: ..., properties: ...)` складає `<event>_<screenName>`. Повна назва має містити
не більше 40 символів; порушення кидає ArgumentError до логування, без обрізання.
Назви та ключі properties — непорожні ідентифікатори `[a-z0-9_]+`.
`onBackClick()` використовує той самий шлях з подією `back_click` та порожніми properties;
довгий suffix може зробити цю подію завеликою, і вона також буде явно відхилена.
Перевірка назв працює навіть коли логування вимкнене.

Properties підтримують лише String, bool, скінченні числа й null; довільні об'єкти не серіалізуються.
Вони призначені тільки для технічних ознак (наприклад source або retry); імена, контакти,
суми, баланси, токени й інші персональні/фінансові значення передавати не можна.
Допустимий тип значення сам по собі не гарантує відсутності приватних даних — це перевіряється
у місці виклику. Home/Splash передають тільки подію opened зі свого event enum через Cubit.

`recordError(error, stackTrace, {fatal: false})` приймає оригінальну помилку та її стек.
Локальний writer передає до `dart:developer.log` безпечний runtimeType помилки у полі error,
стек у stackTrace та fatal у повідомленні. Метод не викликає toString довільного винятку,
щоб випадково не записати секрети чи фінансові значення з його повідомлення.
Repository splash тепер передає стек початкового винятку, а не новий стек у місці логування.

Використовується лише локальний `dart:developer.log`: event/properties — JSON у каналі
`tricount.analytics`, помилки — у `tricount.errors`. Аналітика увімкнена лише для dev;
crash-логи локальні в обох середовищах. Жодного зовнішнього SDK або надсилання даних немає.

## Нова фіча

1. Узгодити поведінку за скриншотом. Створити `features/<name>_feature` і додати до workspace.
2. Додати data/domain/ui, їхні index.dart та публічний barrel. Експортувати тільки контракти й DI,
   у UI — resolver і сторінки. Source/Repository/Interactor — interface + Impl, required named параметри.
3. Зареєструвати три resolver у MainDependenciesModuleResolver; додати залежності common і router.
4. Cubit успадковує SafeCubitWrapper, викликає interactor та analytics, не repository.
5. Додати typed route, LocaleKeys, Semantics identifier для керованих елементів і тематичні стилі.
6. Запустити генерацію з пакета-власника та тести поведінки. Додати короткий CLAUDE.md у фічу.
7. Оновити цей документ, README й команди при зміні структури. Подати PR у develop.

Команди встановлення, запуску й усіх перевірок — у [README](../README.md).
