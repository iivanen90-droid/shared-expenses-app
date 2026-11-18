import 'package:core/core.dart';
import 'package:auth_feature/src/data/repository/auth_repository_impl.dart';
import 'package:auth_feature/src/domain/repository/auth_repository.dart';

abstract interface class AuthDataDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(service: DependencyProvider.get<AuthService>()),
    );
  }
}
