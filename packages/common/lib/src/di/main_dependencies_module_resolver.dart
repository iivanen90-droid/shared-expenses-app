import 'package:core/core.dart';
import 'package:home_feature/home_feature.dart';
import 'package:splash_feature/splash_feature.dart';
import 'package:common/src/initialization/application_initializer.dart';

abstract interface class MainDependenciesModuleResolver {
  static void register({required EnvironmentType environment, ApplicationInitializer? initializer}) {
    CoreDependenciesModuleResolver.register(environment: environment);
    DependencyProvider.registerLazySingleton<ApplicationInitializer>(
      () =>
          initializer ??
          ApplicationInitializerImpl(
            startupStatus: DependencyProvider.get<StartupStatus>(),
            preparePreferences: () => DependencyProvider.get<PreferencesStorage>().initialize(),
            crashReporting: DependencyProvider.get<CrashReportingService>(),
          ),
      dispose: (instance) {
        if (instance is ApplicationInitializerImpl) instance.dispose();
      },
    );
    SplashDataDependencyModuleResolver.register();
    SplashDomainDependencyModuleResolver.register();
    SplashUiDependencyModuleResolver.register();
    HomeDataDependencyModuleResolver.register();
    HomeDomainDependencyModuleResolver.register();
    HomeUiDependencyModuleResolver.register();
  }
}
