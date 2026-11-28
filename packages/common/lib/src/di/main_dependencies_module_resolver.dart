import 'package:main_shell_feature/main_shell_feature.dart';
import 'package:core/core.dart';
import 'package:home_feature/home_feature.dart';
import 'package:splash_feature/splash_feature.dart';
import 'package:common/src/initialization/application_initializer.dart';
import 'package:auth_feature/auth_feature.dart';

abstract interface class MainDependenciesModuleResolver {
  static void register({required EnvironmentType environment}) {
    CoreDependenciesModuleResolver.register(environment: environment);
    DependencyProvider.registerLazySingleton<ApplicationInitializer>(
      () => ApplicationInitializerImpl(
        startupStatus: DependencyProvider.get<StartupStatus>(),
        crashReporting: DependencyProvider.get<CrashReportingService>(),
        authService: DependencyProvider.get<AuthService>(),
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
    AuthDataDependencyModuleResolver.register();
    AuthDomainDependencyModuleResolver.register();
    AuthUiDependencyModuleResolver.register();
  }
}
