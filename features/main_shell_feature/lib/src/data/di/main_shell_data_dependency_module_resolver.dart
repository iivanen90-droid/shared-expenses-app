import 'package:core/core.dart';
import 'package:main_shell_feature/src/data/repository/profile_account_repository_impl.dart';
import 'package:main_shell_feature/src/domain/repository/profile_account_repository.dart';

abstract interface class MainShellDataDependencyModuleResolver {
  static void register() => DependencyProvider.registerLazySingleton<ProfileAccountRepository>(
    () => ProfileAccountRepositoryImpl(
      service: DependencyProvider.get<AuthService>(),
      sessions: DependencyProvider.get<AuthSessionSource>(),
    ),
  );
}
