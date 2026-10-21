import 'package:go_router/go_router.dart';
import 'package:router/src/routes_generator.dart';

abstract interface class GoRouterConfig {
  static GoRouter create() =>
      GoRouter(initialLocation: SplashRoute.path, overridePlatformDefaultLocation: true, routes: $appRoutes);
}
