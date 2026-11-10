import 'package:core/core.dart';
import 'package:home_feature/src/ui/create_group/create_group_cubit.dart';
import 'package:home_feature/src/ui/home/home_analytics.dart';
import 'package:home_feature/src/ui/home/state/home_cubit.dart';

abstract interface class HomeUiDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerFactory<CreateGroupCubit>(() => CreateGroupCubit(interactor: DependencyProvider.get()));
    DependencyProvider.registerFactory<HomeAnalytics>(
      () => HomeAnalyticsImpl(trackerFactory: DependencyProvider.get()),
    );
    DependencyProvider.registerFactory<HomeCubit>(
      () => HomeCubit(analytics: DependencyProvider.get(), interactor: DependencyProvider.get()),
    );
  }
}
