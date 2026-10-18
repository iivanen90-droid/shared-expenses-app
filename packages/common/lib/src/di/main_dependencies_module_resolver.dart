import 'package:core/core.dart';
import 'package:home_feature/home_feature.dart';
import 'package:splash_feature/splash_feature.dart';
import 'package:common/src/initialization/application_initializer.dart';

abstract interface class MainDependenciesModuleResolver {
  static void register({required EnvironmentType environment, ApplicationInitializer? initializer}) {
    DependencyProvider.registerLazySingleton<StartupStatus>(StartupStatusImpl.new);
    DependencyProvider.registerFactory<AnalyticsTracker>(() => AnalyticsTrackerImpl(enabled: environment.isDebug));
    DependencyProvider.registerFactory<CrashReportingService>(CrashReportingServiceImpl.new);
    DependencyProvider.registerFactory<ApplicationInitializer>(
      () => initializer ?? ApplicationInitializerImpl(startupStatus: DependencyProvider.get<StartupStatus>()),
    );
    SplashDataDependencyModuleResolver.register();
    SplashDomainDependencyModuleResolver.register();
    SplashUiDependencyModuleResolver.register();
    HomeDataDependencyModuleResolver.register();
    HomeDomainDependencyModuleResolver.register();
    HomeUiDependencyModuleResolver.register();
  }
}
