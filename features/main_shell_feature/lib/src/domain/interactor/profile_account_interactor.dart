import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/repository/profile_account_repository.dart';

abstract interface class ProfileAccountInteractor {
  AuthenticationSnapshot get snapshot;
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}

final class ProfileAccountInteractorImpl implements ProfileAccountInteractor {
  const ProfileAccountInteractorImpl({required this._repository});
  final ProfileAccountRepository _repository;
  @override
  AuthenticationSnapshot get snapshot => _repository.snapshot;
  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => _repository.watchStatus();
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _repository.signOut();
}
