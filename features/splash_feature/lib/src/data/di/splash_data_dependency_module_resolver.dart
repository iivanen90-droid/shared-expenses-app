import 'package:core/core.dart';
import 'package:splash_feature/src/data/repository/startup_repository.dart';
import 'package:splash_feature/src/data/repository/startup_repository_impl.dart';
import 'package:splash_feature/src/data/source/startup_source.dart';

abstract interface class SplashDataDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerFactory<StartupSource>(
      () => StartupSourceImpl(startupStatus: DependencyProvider.get(), initializer: DependencyProvider.get()),
    );
    DependencyProvider.registerFactory<StartupRepository>(
      () => StartupRepositoryImpl(source: DependencyProvider.get(), crashReporting: DependencyProvider.get()),
    );
  }
}
