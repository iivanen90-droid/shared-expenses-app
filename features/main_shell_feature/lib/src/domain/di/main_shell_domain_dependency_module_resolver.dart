import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_interactor.dart';
import 'package:main_shell_feature/src/domain/repository/profile_repository.dart';

abstract interface class MainShellDomainDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerLazySingleton<ProfileInteractor>(
      () => ProfileInteractorImpl(repository: DependencyProvider.get<ProfileRepository>()),
    );
  }
}
