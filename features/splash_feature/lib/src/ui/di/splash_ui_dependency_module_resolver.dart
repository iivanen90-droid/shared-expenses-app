import 'package:core/core.dart';
import 'package:splash_feature/src/domain/interactor/startup_interactor.dart';
import 'package:splash_feature/src/ui/splash/splash_analytics.dart';
import 'package:splash_feature/src/ui/splash/state/splash_cubit.dart';

abstract interface class SplashUiDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerFactory<SplashAnalytics>(
      () => SplashAnalyticsImpl(trackerFactory: DependencyProvider.get<AnalyticsTrackerFactory>()),
    );
    DependencyProvider.registerFactory<SplashCubit>(
      () => SplashCubit(
        interactor: DependencyProvider.get<StartupInteractor>(),
        analytics: DependencyProvider.get<SplashAnalytics>(),
      ),
    );
  }
}
