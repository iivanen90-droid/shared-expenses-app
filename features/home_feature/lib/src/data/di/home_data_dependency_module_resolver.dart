import 'package:core/core.dart';
import 'package:home_feature/objectbox.g.dart';
import 'package:home_feature/src/data/repository/home_groups_repository_impl.dart';
import 'package:home_feature/src/data/source/home_groups_source.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';

abstract interface class HomeDataDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerLazySingleton<HomeGroupsSource>(
      () => ObjectBoxHomeGroupsSource(openDatabase: () => ObjectBoxDatabase.open(openStore)),
      dispose: (source) async {
        if (source is ObjectBoxHomeGroupsSource) await source.close();
      },
    );
    DependencyProvider.registerLazySingleton<HomeGroupsRepository>(
      () => HomeGroupsRepositoryImpl(source: DependencyProvider.get()),
    );
  }
}
