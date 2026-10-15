# Спільні витрати

Початковий Flutter-проєкт мобільного застосунку для обліку та розподілу спільних витрат.
Наразі містить лише стартовий екран із назвою, без лічильника та бізнес-функціоналу.

## Інструменти

- Flutter 3.47.5 (stable).
- Dart 3.13.4, який входить до цієї версії Flutter.
- Для запуску Android: Android SDK та емулятор або телефон із налагодженням через USB.
- Збірка і запуск iOS потребують macOS та Xcode.

## Встановлення залежностей

У терміналі в корені проєкту:

```sh
flutter pub get
```

## Перевірка коду

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

Для виправлення форматування: `dart format lib test`.
Правила роботи агента та рекомендації для code review містяться в `AGENTS.md`.

### Автоматична перевірка в GitHub

Workflow `.github/workflows/flutter-checks.yml` запускає перевірку форматування,
аналіз коду та тести на кожен push і pull request. Результати доступні у вкладці
**Actions** і в перевірках pull request після відправлення цих файлів у GitHub.
Використовується Flutter 3.47.5; при оновленні SDK змінюй також версію у workflow.

### Codex code review

Окремо увімкни автоматичний code review для цього репозиторію в налаштуваннях
Codex і вибери тригер перевірки після кожного push у pull request.
`AGENTS.md` задає правила перевірки, але сам не вмикає цей перемикач.
Якщо налаштування не збереглися, онови сторінку й перевір їх повторно.
У підключеному репозиторії review також можна запросити коментарем `@codex review`
у pull request. Звичайний push без pull request не є запитом Codex review.

Офіційна інструкція: [Codex review у GitHub](https://developers.openai.com/codex/integrations/github).

## Запуск

Запустіть Android-емулятор або підключіть телефон. Перевірте доступні пристрої:

```sh
flutter devices
```

Запустіть застосунок:

```sh
flutter run
```

Якщо доступно декілька пристроїв, оберіть потрібний у терміналі.
Точка входу: `lib/main.dart`.

Збірки, кеші, локальні налаштування IDE та файли секретів виключені через `.gitignore`.
`pubspec.lock` і `.metadata` потрібно зберігати у Git.
