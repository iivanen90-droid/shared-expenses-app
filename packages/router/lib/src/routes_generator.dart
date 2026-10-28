import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_feature/home_feature.dart';
import 'package:main_shell_feature/main_shell_feature.dart';
import 'package:router/src/go_router_config.dart';
import 'package:router/src/route_model.dart';
import 'package:splash_feature/splash_feature.dart';

part 'routes_generator.g.dart';

Page<void> buildPlatformPage({required BuildContext context, required GoRouterState state, required Widget child}) {
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
      buildPlatformPage(context: context, state: state, child: const SplashPage());
}

@TypedStatefulShellRoute<MainShellRoute>(
  branches: [
    TypedStatefulShellBranch<HomeBranch>(
      routes: [
        TypedGoRoute<HomeRoute>(
          path: '/home',
          routes: [TypedGoRoute<HomeDetailsRoute>(path: 'details')],
        ),
      ],
    ),
    TypedStatefulShellBranch<SecondBranch>(
      routes: [
        TypedGoRoute<SecondTabRoute>(
          path: '/second',
          routes: [TypedGoRoute<SecondDetailsRoute>(path: 'details')],
        ),
      ],
    ),
  ],
)
class MainShellRoute extends StatefulShellRouteData {
  const MainShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) => MainShellPage(
    currentIndex: navigationShell.currentIndex,
    onDestinationSelected: (index) => navigationShell.goBranch(index),
    child: navigationShell,
  );
}

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
  static final GlobalKey<NavigatorState> $navigatorKey = GoRouterConfig.homeNavigatorKey;
}

class SecondBranch extends StatefulShellBranchData {
  const SecondBranch();
  static final GlobalKey<NavigatorState> $navigatorKey = GoRouterConfig.secondNavigatorKey;
}

@immutable
class HomeRoute extends GoRouteData with $HomeRoute implements RouteModel {
  const HomeRoute();
  static const path = '/home';
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => buildPlatformPage(
    context: context,
    state: state,
    child: HomePage(onOpenDetails: () => context.pushTo<void>(const HomeDetailsRoute())),
  );
}

@immutable
class HomeDetailsRoute extends GoRouteData with $HomeDetailsRoute implements RouteModel {
  const HomeDetailsRoute();
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => buildPlatformPage(
    context: context,
    state: state,
    child: const TabDetailsPage(identifier: 'home_details'),
  );
}

@immutable
class SecondTabRoute extends GoRouteData with $SecondTabRoute implements RouteModel {
  const SecondTabRoute();
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => buildPlatformPage(
    context: context,
    state: state,
    child: SecondTabPage(onOpenDetails: () => context.pushTo<void>(const SecondDetailsRoute())),
  );
}

@immutable
class SecondDetailsRoute extends GoRouteData with $SecondDetailsRoute implements RouteModel {
  const SecondDetailsRoute();
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => buildPlatformPage(
    context: context,
    state: state,
    child: const TabDetailsPage(identifier: 'second_details'),
  );
}
