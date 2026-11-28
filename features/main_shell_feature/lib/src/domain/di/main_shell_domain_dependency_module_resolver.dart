import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_account_interactor.dart';
import 'package:main_shell_feature/src/domain/repository/profile_account_repository.dart';

abstract interface class MainShellDomainDependencyModuleResolver {
  static void register() => DependencyProvider.registerLazySingleton<ProfileAccountInteractor>(
    () => ProfileAccountInteractorImpl(repository: DependencyProvider.get<ProfileAccountRepository>()),
  );
}
