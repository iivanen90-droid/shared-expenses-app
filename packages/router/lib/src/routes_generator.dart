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
          path: HomeRoute.path,
          routes: [
            TypedGoRoute<CreateGroupRoute>(path: 'new'),
            TypedGoRoute<GroupCreatedRoute>(path: 'created/:groupId'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<ProfileBranch>(routes: [TypedGoRoute<ProfileRoute>(path: ProfileRoute.path)]),
  ],
)
class MainShellRoute extends StatefulShellRouteData {
  const MainShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) =>
      MainShellPage(navigationShell: navigationShell);
}

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
  static final GlobalKey<NavigatorState> $navigatorKey = GoRouterConfig.homeNavigatorKey;
}

class ProfileBranch extends StatefulShellBranchData {
  const ProfileBranch();
  static final GlobalKey<NavigatorState> $navigatorKey = GoRouterConfig.profileNavigatorKey;
}

@immutable
class HomeRoute extends GoRouteData with $HomeRoute implements RouteModel {
  const HomeRoute();
  static const path = '/home';
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildPlatformPage(context: context, state: state, child: const HomePage());
}

@immutable
class CreateGroupRoute extends GoRouteData with $CreateGroupRoute implements RouteModel {
  const CreateGroupRoute();
  static final GlobalKey<NavigatorState> $parentNavigatorKey = GoRouterConfig.rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildPlatformPage(context: context, state: state, child: const CreateGroupPage());
}

@immutable
class GroupCreatedRoute extends GoRouteData with $GroupCreatedRoute implements RouteModel {
  const GroupCreatedRoute({required this.groupId});
  static final GlobalKey<NavigatorState> $parentNavigatorKey = GoRouterConfig.rootNavigatorKey;
  final int groupId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildPlatformPage(context: context, state: state, child: const GroupCreatedPage());
}

@immutable
class ProfileRoute extends GoRouteData with $ProfileRoute implements RouteModel {
  const ProfileRoute();
  static const path = '/profile';
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildPlatformPage(context: context, state: state, child: const ProfilePage());
}
