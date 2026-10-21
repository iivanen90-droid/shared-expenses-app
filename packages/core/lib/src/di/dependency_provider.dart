import 'package:get_it/get_it.dart';

abstract interface class DependencyProvider {
  static T get<T extends Object>() => GetIt.instance<T>();
  static T? getOrNull<T extends Object>() => isRegistered<T>() ? get<T>() : null;
  static T getWithParams<T extends Object>({Object? param1, Object? param2}) =>
      GetIt.instance<T>(param1: param1, param2: param2);
  static void registerFactory<T extends Object>(T Function() factory) => GetIt.instance.registerFactory<T>(factory);
  static void registerLazySingleton<T extends Object>(T Function() factory) =>
      GetIt.instance.registerLazySingleton<T>(factory);
  static void registerFactoryWithParams<T extends Object, P1, P2>(T Function(P1, P2) factory) =>
      GetIt.instance.registerFactoryParam<T, P1, P2>(factory);
  static bool isRegistered<T extends Object>() => GetIt.instance.isRegistered<T>();
  static Future<void> reset() => GetIt.instance.reset();
}
