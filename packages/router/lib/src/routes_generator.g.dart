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
            GoRouteData.$route(path: 'details', hasOverriddenOnExit: false, factory: $HomeDetailsRoute._fromState),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      navigatorKey: SecondBranch.$navigatorKey,
      routes: [
        GoRouteData.$route(
          path: '/second',
          hasOverriddenOnExit: false,
          factory: $SecondTabRoute._fromState,
          routes: [
            GoRouteData.$route(path: 'details', hasOverriddenOnExit: false, factory: $SecondDetailsRoute._fromState),
          ],
        ),
      ],
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

mixin $HomeDetailsRoute on GoRouteData {
  static HomeDetailsRoute _fromState(GoRouterState state) => const HomeDetailsRoute();

  @override
  String get location => GoRouteData.$location('/home/details');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SecondTabRoute on GoRouteData {
  static SecondTabRoute _fromState(GoRouterState state) => const SecondTabRoute();

  @override
  String get location => GoRouteData.$location('/second');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SecondDetailsRoute on GoRouteData {
  static SecondDetailsRoute _fromState(GoRouterState state) => const SecondDetailsRoute();

  @override
  String get location => GoRouteData.$location('/second/details');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
