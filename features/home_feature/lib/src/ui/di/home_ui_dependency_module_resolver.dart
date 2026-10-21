import 'package:core/core.dart';
import 'package:home_feature/src/ui/home/home_analytics.dart';
import 'package:home_feature/src/ui/home/state/home_cubit.dart';

abstract interface class HomeUiDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerFactory<HomeAnalytics>(() => HomeAnalyticsImpl(tracker: DependencyProvider.get()));
    DependencyProvider.registerFactory<HomeCubit>(() => HomeCubit(analytics: DependencyProvider.get()));
  }
}
