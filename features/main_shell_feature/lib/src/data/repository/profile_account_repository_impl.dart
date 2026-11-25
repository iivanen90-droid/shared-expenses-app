import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/repository/profile_account_repository.dart';

final class ProfileAccountRepositoryImpl implements ProfileAccountRepository {
  const ProfileAccountRepositoryImpl({required this._service});
  final AuthService _service;
  @override
  AuthenticationSnapshot get snapshot => _service.snapshot;
  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => _service.watchStatus();
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _service.signOut();
}
