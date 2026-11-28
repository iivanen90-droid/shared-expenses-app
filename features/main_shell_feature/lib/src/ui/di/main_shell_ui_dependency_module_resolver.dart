import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_interactor.dart';
import 'package:main_shell_feature/src/ui/profile/profile_cubit.dart';

abstract interface class MainShellUiDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerFactory<ProfileCubit>(
      () => ProfileCubit(interactor: DependencyProvider.get<ProfileInteractor>()),
    );
  }
}
