// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_generator.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$splashRoute, $mainShellRoute];

RouteBase get $splashRoute =>
    GoRouteData.$route(path: '/splash', hasOverriddenOnExit: false, factory: $SplashRoute._fromState);

mixin $SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location('/splash');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $mainShellRoute => StatefulShellRouteData.$route(
  factory: $MainShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      navigatorKey: HomeBranch.$navigatorKey,
      routes: [
        GoRouteData.$route(
          path: '/home',
          hasOverriddenOnExit: false,
          factory: $HomeRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              hasOverriddenOnExit: false,
              parentNavigatorKey: CreateGroupRoute.$parentNavigatorKey,
              factory: $CreateGroupRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'created/:groupId',
              hasOverriddenOnExit: false,
              parentNavigatorKey: GroupCreatedRoute.$parentNavigatorKey,
              factory: $GroupCreatedRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      navigatorKey: ProfileBranch.$navigatorKey,
      routes: [GoRouteData.$route(path: '/profile', hasOverriddenOnExit: false, factory: $ProfileRoute._fromState)],
    ),
  ],
);

extension $MainShellRouteExtension on MainShellRoute {
  static MainShellRoute _fromState(GoRouterState state) => const MainShellRoute();
}

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/home');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CreateGroupRoute on GoRouteData {
  static CreateGroupRoute _fromState(GoRouterState state) => const CreateGroupRoute();

  @override
  String get location => GoRouteData.$location('/home/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GroupCreatedRoute on GoRouteData {
  static GroupCreatedRoute _fromState(GoRouterState state) =>
      GroupCreatedRoute(groupId: int.parse(state.pathParameters['groupId']!));

  GroupCreatedRoute get _self => this as GroupCreatedRoute;

  @override
  String get location => GoRouteData.$location('/home/created/${Uri.encodeComponent(_self.groupId.toString())}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProfileRoute on GoRouteData {
  static ProfileRoute _fromState(GoRouterState state) => const ProfileRoute();

  @override
  String get location => GoRouteData.$location('/profile');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
