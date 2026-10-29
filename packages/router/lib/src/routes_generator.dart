import 'package:go_router/go_router.dart';
import 'package:home_feature/home_feature.dart';
import 'package:flutter/material.dart';
import 'package:router/src/route_model.dart';
import 'package:splash_feature/splash_feature.dart';
part 'routes_generator.g.dart';

MaterialPage<void> buildAppPage({required GoRouterState state, required Widget child}) =>
    MaterialPage<void>(key: state.pageKey, child: child);

@TypedGoRoute<SplashRoute>(path: SplashRoute.path)
@immutable
class SplashRoute extends GoRouteData with $SplashRoute implements RouteModel {
  const SplashRoute();
  static const path = '/splash';
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildAppPage(state: state, child: const SplashPage());
}

@TypedGoRoute<HomeRoute>(path: HomeRoute.path)
@immutable
class HomeRoute extends GoRouteData with $HomeRoute implements RouteModel {
  const HomeRoute();
  static const path = '/home';
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildAppPage(state: state, child: const HomePage());
}
