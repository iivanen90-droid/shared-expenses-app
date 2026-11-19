import 'package:core/core.dart';
import 'package:auth_feature/src/domain/interactor/auth_interactor.dart';
import 'package:auth_feature/src/ui/auth/auth_cubit.dart';

abstract interface class AuthUiDependencyModuleResolver {
  static void register() {
    DependencyProvider.registerFactory<AuthCubit>(
      () => AuthCubit(interactor: DependencyProvider.get<AuthInteractor>()),
    );
  }
}
