import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:router/src/routes_generator.dart';

abstract interface class GoRouterConfig {
  static final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
  static final secondNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'second');

  /// The application owns and disposes this router; read once per App instance.
  static GoRouter get config => GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: SplashRoute.path,
    overridePlatformDefaultLocation: true,
    routes: $appRoutes,
  );

  static GoRouter create() => config;
}
