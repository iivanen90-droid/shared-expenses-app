import 'package:core/core.dart';
import 'package:splash_feature/src/domain/interactor/startup_interactor.dart';
import 'package:splash_feature/src/domain/interactor/startup_interactor_impl.dart';

abstract interface class SplashDomainDependencyModuleResolver {
  static void register() => DependencyProvider.registerFactory<StartupInteractor>(
    () => StartupInteractorImpl(repository: DependencyProvider.get()),
  );
}
