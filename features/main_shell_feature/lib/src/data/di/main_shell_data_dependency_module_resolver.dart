import 'package:core/core.dart';
import 'package:main_shell_feature/src/data/source/profile_source.dart';
import 'package:main_shell_feature/src/data/repository/profile_repository_impl.dart';
import 'package:main_shell_feature/src/domain/repository/profile_repository.dart';

abstract interface class MainShellDataDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerLazySingleton<ProfileSource>(
      () => ProfileSourceImpl(
        auth: DependencyProvider.get<AuthService>(),
        languages: DependencyProvider.get<LanguagePreferences>(),
      ),
    );
    DependencyProvider.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(source: DependencyProvider.get<ProfileSource>()),
    );
  }
}
