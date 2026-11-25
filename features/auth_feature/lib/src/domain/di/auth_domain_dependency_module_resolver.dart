import 'package:core/core.dart';
import 'package:auth_feature/src/domain/interactor/auth_interactor.dart';
import 'package:auth_feature/src/domain/repository/auth_repository.dart';

abstract interface class AuthDomainDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerFactory<AuthInteractor>(
      () => AuthInteractorImpl(repository: DependencyProvider.get<AuthRepository>()),
    );
  }
}
