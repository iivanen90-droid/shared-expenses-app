import 'package:flutter/widgets.dart';

abstract interface class RouteModel {
  void go(BuildContext context);
  Future<T?> push<T>(BuildContext context);
}

extension AppNavigation on BuildContext {
  void goTo(RouteModel route) => route.go(this);
  Future<T?> pushTo<T>(RouteModel route) => route.push<T>(this);
  void maybePop() => Navigator.of(this).maybePop();
}
