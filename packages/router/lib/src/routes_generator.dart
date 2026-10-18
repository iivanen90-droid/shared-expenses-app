import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPage;
import 'package:go_router/go_router.dart';
import 'package:home_feature/home_feature.dart';
import 'package:material_ui/material_ui.dart';
import 'package:router/src/route_model.dart';
import 'package:splash_feature/splash_feature.dart';
part 'routes_generator.g.dart';

Page<void> buildPlatformPage({required GoRouterState state, required Widget child, required BuildContext context}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: state.pageKey, child: child);
  }
  return MaterialPage<void>(key: state.pageKey, child: child);
}

@TypedGoRoute<SplashRoute>(path: SplashRoute.path)
@immutable
class SplashRoute extends GoRouteData with $SplashRoute implements RouteModel {
  const SplashRoute();
  static const path = '/splash';
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildPlatformPage(state: state, child: const SplashPage(), context: context);
}

@TypedGoRoute<HomeRoute>(path: HomeRoute.path)
@immutable
class HomeRoute extends GoRouteData with $HomeRoute implements RouteModel {
  const HomeRoute();
  static const path = '/home';
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildPlatformPage(state: state, child: const HomePage(), context: context);
}
