import 'package:main_shell_feature/main_shell_feature.dart';
import 'package:core/core.dart';
import 'package:home_feature/home_feature.dart';
import 'package:splash_feature/splash_feature.dart';
import 'package:common/src/initialization/application_initializer.dart';

abstract interface class MainDependenciesModuleResolver {
  static void register({
    required EnvironmentType environment,
    DioClientConfiguration dioConfiguration = const DioClientConfiguration(),
  }) {
    CoreDependenciesModuleResolver.register(environment: environment, dioConfiguration: dioConfiguration);
    DependencyProvider.registerLazySingleton<ApplicationInitializer>(
      () => ApplicationInitializerImpl(
        startupStatus: DependencyProvider.get<StartupStatus>(),
        crashReporting: DependencyProvider.get<CrashReportingService>(),
      ),
      dispose: (instance) {
        if (instance is ApplicationInitializerImpl) instance.dispose();
      },
    );
    SplashDataDependencyModuleResolver.register();
    SplashDomainDependencyModuleResolver.register();
    SplashUiDependencyModuleResolver.register();
    MainShellDataDependencyModuleResolver.register();
    MainShellDomainDependencyModuleResolver.register();
    MainShellUiDependencyModuleResolver.register();
    HomeDataDependencyModuleResolver.register();
    HomeDomainDependencyModuleResolver.register();
    HomeUiDependencyModuleResolver.register();
  }
}
