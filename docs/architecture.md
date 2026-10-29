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
| `packages/router/` | Типізовані маршрути splash і двох вкладок, окремі Navigator та навігаційні розширення |
| `features/splash_feature/` | Перевірка готовності, loading/loaded/failed, повтор після помилки та перехід на home |
| `features/main_shell_feature/` | Оболонка двох вкладок, порожні сторінки та data/domain/ui-resolver-и |
| `features/home_feature/` | Наявний стартовий екран, стан і подія відкриття; фінансових функцій немає |
| `envs/` | Безпечні dev/prod приклади; приватні конфігурації ігноруються Git |
| `tools/` | Команди workspace, codegen, локалізація, форматування, аналіз і тести |
| `.maestro/` | Сценарій перевірки стартового екрана на встановленому dev-застосунку |

## Залежності та потік

`core` й `ui_kit` не імпортують інші пакети workspace. `mobile` збирає common, router і ui_kit.
`common` реєструє DI фіч; router будує їхні сторінки. Фічі використовують публічні barrels common,
core, router, ui_kit. Зв'язки common ↔ feature ↔ router відповідають довіднику; чужий `src/` заборонений.
Прямі імпорти feature → feature заборонені. Спільні контракти надалі додаються в core.

Запуск: binding → ensureSemantics лише в debug → await EasyLocalization.ensureInitialized() →
await SystemChrome.setPreferredOrientations([portraitUp]) → DI (core, потім data → domain → ui кожної фічі) →
await ApplicationInitializer.initialize() → runApp(LocalizationsWrapper(child: App())) → splash → вкладки.
Ініціалізатор встановлює обробники помилок і очікує готовності preferences до runApp.
Паралельні виклики ділять один Future; після успіху повторна підготовка не виконується.
При помилці підготовки запуск записує її в локальний CrashReportingService та відкриває
оболонку відновлення: splash повторює ініціалізацію через repository, а при повторній
невдачі показує кнопку повтору. StartupStatus стає ready лише після успіху.

ApplicationInitializer — контракт у core, також експортований через common.dart.
MainDependenciesModuleResolver реєструє реалізацію як lazy singleton; reset DI звільняє
її та відновлює попередні глобальні обробники, якщо вони ще належать цьому екземпляру.
FlutterError.onError передає помилку та стек у CrashReportingService з fatal: false,
після чого викликає попередній Flutter-обробник. PlatformDispatcher.onError перехоплює
необроблені async-помилки головного isolate з fatal: true і зберігає результат попереднього
обробника, якщо він є. Без попереднього обробника повертає успішність локального логування.
Помилка самого reporter не створює рекурсивного звіту. Помилки окремих isolate потрібно
передавати окремо; зовнішні SDK не підключені.
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
нативний Flutter-registrant підключає плагін. ApplicationInitializer очікує
PreferencesStorage.initialize(): одноразовий read-only getKeys перевіряє доступ до платформи,
не записуючи бізнес-ключів. Конкурентні звернення очікують спільний Future; після помилки
можна повторити підготовку. Усі читання, записи та remove також очікують initialize(),
тому прямий споживач не обходить підготовку. Значення не кешуються.
SharedPreferences.getInstance() для async API не потрібний.
У тестах використовується офіційний in-memory async backend;
shared_preferences_platform_interface — test-залежність core та mobile з версією в root.

Сховище призначене для некритичних налаштувань, а не фінансових записів чи секретів.
Обгортка не додає бізнес-ключів, не логує ключі/значення та не змінює сховище локалізації
всередині easy_localization. Окремих налаштувань користувача в UI поки немає.

## UI, генерація та середовища

UI імпортується зі стандартного `package:flutter/material.dart`; окремі пакети material_ui/cupertino_ui не використовуються напряму.
buildPlatformPage задає SDK MaterialPage на Android і CupertinoPage на iOS, зберігаючи Material-віджети та спільну тему.
Стилі — через AppThemeProvider і context-розширення;
рядки — через згенеровані LocaleKeys та easy_localization. Підтримуються en/uk:
збережена або підтримувана системна мова; англійська — fallback для непідтримуваної
мови та відсутнього перекладу. Екрану зміни мови ще немає.
Стани — один freezed-клас зі status enum. Routes — go_router_builder. Assets — flutter_gen.
Генеровані файли комітяться, вручну їх не змінюємо.

Android має productFlavors dev/prod, iOS — відповідні shared schemes і Debug/Profile/Release конфігурації.
Dev має окремий application/bundle id із суфіксом `.dev`. ENVIRONMENT із dart-define має збігатися
з native flavor. Приклади не містять секретів. Production-підпис і публікація в магазинах не налаштовані.
Аналітика в dev локально записує назву події та технічні properties; дані користувача передавати заборонено.
CrashReportingService локально записує тип помилки, стек і fatal, не повідомлення довільного винятку.

Мережевий клієнт і preferences — обгортки без активних серверних запитів чи фінансових даних.
ObjectBox, DTO/json_serializable та бізнес-модулі додаються з першим
погодженим сценарієм, коли є відповідні дані/API/вкладки. Це не реалізовані можливості оболонки.

## Базова тема ui_kit

Одна тема `AppTheme.main()` використовує Flutter Material 3 з базовим синім seed.
`AppColorScheme` надає primary/onPrimary, surface/onSurface/onSurfaceVariant, outline, error/onError.
`AppTextStyles` містить heading, title, body, label і caption, побудовані зі стандартного TextTheme.
Файлів шрифтів і fontFamily override немає; використовується стандартна типографіка Flutter.

`AppThemeProvider` — InheritedWidget, який у mobile обгортає `MaterialApp.router`.
`theme.material` задається в MaterialApp, а споживачі читають `context.colors` та `context.texts`
через публічний `ui_kit.dart`. Зміна екземпляра теми сповіщає залежні віджети, найближчий
provider має пріоритет; звернення без provider завершується явним StateError.
`context.icons` збережено для поточної кнопки повтору. Нові кольори й стилі додаються в ui_kit,
а не задаються окремо на кожному екрані.

Віджети Home/Splash використовують Flutter Material; сторінки маршрутів — SDK MaterialPage / CupertinoPage. Локалізаційні делегати
тепер беруться з SDK flutter_localizations і easy_localization, включно з українською.
Прямі залежності material_ui/cupertino_ui видалені з усіх workspace pubspec; go_router 18.1.0
усе ще залежить від них транзитивно. Його версію для цієї задачі не змінюємо.

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

## Оболонка вкладок і маршрути

GoRouterConfig.config створює router з initialLocation: /splash. App читає config один раз
і викликає dispose. Ключі root, home та second Navigator визначені в GoRouterConfig;
кожна TypedStatefulShellBranch посилається на свій ключ.
MainShellRoute оголошений через @TypedStatefulShellRoute й використовує стандартний IndexedStack.
MainShellPage отримує child, currentIndex та callback, а router викликає goBranch без скидання
initialLocation. Перемикання, зокрема повторний вибір активної вкладки, зберігає її стек.

Після успішної ініціалізації splash викликає context.goTo(const HomeRoute()) — go замінює
маршрут, тому Back із кореня вкладки не відкриває splash. Окремого native splash не додано.
Перша вкладка /home зберігає стартовий HomePage, друга /second містить порожній екран.
Маршрути /home/details і /second/details — порожні сторінки для перевірки вкладених стеків,
не реалізовані сценарії витрат. Кнопки відкривають їх через context.pushTo; Back закриває
сторінку тільки в активному Navigator. Стан не відновлюється після завершення процесу.

buildPlatformPage повертає Flutter SDK MaterialPage на Android та CupertinoPage на iOS,
як у довіднику. Це змінює лише тип переходів: віджети, AppTheme.main(), кольори й тексти
залишаються стандартними Flutter Material. Зовнішні material_ui/cupertino_ui не повертаються.
Тонкі обгортки context.pushTo/goTo делегують згенерованим push/go, без перевірок типів route.
Фіча main_shell_feature не імпортує інші фічі та отримує callbacks від router.
Решта feature DI як і раніше реєструється в common у порядку data → domain → ui.

Генерація після зміни routes (із packages/router):

~~~sh
fvm dart run build_runner build --force-jit
~~~

Перевірка вручну: splash → перша вкладка → «Відкрити деталі» → друга вкладка →
«Відкрити деталі» → перша вкладка (її деталі збережені) → Back → друга вкладка
(її деталі збережені) → Back. Із кореня вкладки Back не має відкривати splash.
Тести mobile також перевіряють зміну мови без втрати обох стеків.

Тема та локалізація з PR #14–#15 уже входять до develop. Ця гілка включає оновлений PR #16 з ініціалізацією.
Їхні конфлікти узгоджені; перевірки виконуються для спільного результату.
PR навігації слід зливати після попередніх PR та повторної перевірки актуального develop.

## Оболонка mobile і старт

main.dart містить лише вибір EnvironmentType та виклик асинхронного run із main_common.dart.
Debug semantics вмикаються один раз на час життя застосунку; у release цього виклику немає.
Локалізація ініціалізується перед portraitUp, а завершення платформного запиту орієнтації
очікується перед реєстрацією DI. MainDependenciesModuleResolver.register наразі синхронний;
якщо він стане асинхронним, його Future потрібно очікувати перед ApplicationInitializer.

run очікує initializer до створення дерева App. Успішний initializer позначає StartupStatus ready;
splash лише перевіряє цей стан і через go переходить до вкладок, без повторної ініціалізації.
Наявне відновлення після невдалої підготовки preferences збережене: лише за відсутності ready
splash може повторити невдалу спробу й показати явну кнопку повтору.
AppThemeProvider обгортає MaterialApp.router; один router живе до dispose App,
поточні localizationDelegates/supportedLocales/locale оновлюють UI без створення нового router.

FlutterError.onError і PlatformDispatcher.onError встановлюються виключно в
ApplicationInitializer; main_common не створює дубльованих обробників.
CrashReportingService отримує оригінальні error/stackTrace; локальний writer записує
безпечний тип помилки, стек і fatal. Зовнішніх crash SDK немає.
Для ручної перевірки можна тимчасово викликати FlutterError.reportError або незловлену
async-помилку в debug, перевірити канал tricount.errors і видалити виклик до коміту.
Для перевірки через VM service зміни джерел узагалі не потрібні.

Ручний чекліст для Android та iOS:
1. Запустити dev flavor: початкова ініціалізація завершується перед splash → вкладки.
2. Переконатися в портретній орієнтації, перевірити uk та en через локалізаційний контекст.
3. Викликати навмисну framework/async-помилку та перевірити error/stack/fatal у tricount.errors.
4. Перевірити, що після тесту не залишилося викликів помилок у джерелах.
iOS native запуск потребує macOS/Xcode; widget-тест із платформою iOS його не замінює.
Flutter може ігнорувати orientation lock на iPad із multitasking та Android 16 на великих
дисплеях; конфігурацію multitasking цим етапом не змінюємо.

## Мережевий клієнт core

DioClient реалізує ApiClient для майбутніх data/source-сервісів. Публічний core.dart
експортує обидва типи, DioClientConfiguration, ApiError/ApiErrorKind і потрібні
CancelToken/Interceptor/InterceptorsWrapper. Dio вже був у core та root pubspec;
версія й lockfile цим етапом не оновлюються.

Конфігурація передається у конструктор, CoreDependenciesModuleResolver.register
або MainDependenciesModuleResolver.register через dioConfiguration:
baseUrl, connectTimeout (15 с), sendTimeout (30 с), receiveTimeout (30 с) та headers.
Таймаути мають бути додатніми; непорожній baseUrl — абсолютний HTTP(S) URL.
Клієнт копіює мапу заголовків; заголовки окремого запиту не змінюють налаштування наступних.
Адреса бекенду поки не визначена: типовий baseUrl порожній, жодних запитів при старті немає.
Відносний запит без базової адреси повертає Left(ApiErrorKind.configuration) без транспорту;
абсолютний HTTP(S) URL можна передати явно. Реальних endpoints і бізнес-сервісів не додано.

Доступні get/post/put/patch/delete/head та request із method, data, queryParameters,
headers, cancelToken і обов'язковим decode(Object?). Метод повертає Future<Either<ApiError,T>>;
ApiError extends Failure, тому repository може перевести транспортну помилку
у Failure конкретного сценарію. Right містить результат decoder, Left — безпечний
kind та, якщо доступний, statusCode. Немає response body, URL, заголовків чи повідомлень винятку в ApiError.
HTTP-помилки не передаються decoder; помилки JSON/decoder мають kind decoding.
Мережеві помилки, таймаути, сертифікат, HTTP, скасування й невідомі помилки розрізняються.
Автоматичних retries, авторизації, refresh token чи прихованих повторів запису немає.

Interceptors можна передати конструктору або додати через addInterceptor.
Транспортні помилки та помилки decoder передаються наявному CrashReportingService
з оригінальними error/stackTrace. Локальний writer записує тільки безпечний тип, стек і fatal,
без request/response payload, URL або заголовків. Скасування не записується як crash.
Помилка reporter не перетворює Either на необроблений виняток. LogInterceptor автоматично не додається;
нові interceptors не повинні логувати секрети чи фінансові дані.

Core DI реєструє один lazy DioClient та ApiClient як посилання на той самий екземпляр.
await DependencyProvider.reset() закриває створений клієнт через close(force: true);
невикористаний клієнт при reset не створюється. close ідемпотентний, нові запити після нього
повертають kind closed. Самостійно створений клієнт закриває його власник.
ApiClientImpl(dio: ...) збережений як сумісний конструктор для попереднього API;
для нового коду потрібні DioClientConfiguration та ін'єкція CrashReportingService.
