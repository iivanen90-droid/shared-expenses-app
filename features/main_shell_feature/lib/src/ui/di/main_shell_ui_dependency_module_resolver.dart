import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_account_interactor.dart';
import 'package:main_shell_feature/src/ui/profile/profile_account_cubit.dart';

abstract interface class MainShellUiDependencyModuleResolver {
  static void register() => DependencyProvider.registerFactory<ProfileAccountCubit>(
    () => ProfileAccountCubit(interactor: DependencyProvider.get<ProfileAccountInteractor>()),
  );
}
