import 'dart:developer' as developer;

typedef DeveloperLogWriter = void Function(
  String message, {
  required String name,
  Object? error,
  StackTrace? stackTrace,
});

void writeDeveloperLog(String message, {required String name, Object? error, StackTrace? stackTrace}) =>
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
