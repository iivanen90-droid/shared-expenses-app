import 'package:core/core.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';

abstract interface class HomeDomainDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerLazySingleton<HomeGroupsInteractor>(
      () => HomeGroupsInteractorImpl(repository: DependencyProvider.get<HomeGroupsRepository>()),
    );
  }
}
