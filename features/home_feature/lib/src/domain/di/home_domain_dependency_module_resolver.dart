import 'package:core/core.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';

abstract interface class HomeDomainDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerLazySingleton<HomeGroupsInteractor>(
      () => HomeGroupsInteractorImpl(repository: DependencyProvider.get()),
    );
  }
}
