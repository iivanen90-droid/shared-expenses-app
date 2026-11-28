import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/repository/profile_account_repository.dart';

final class ProfileAccountRepositoryImpl implements ProfileAccountRepository {
  const ProfileAccountRepositoryImpl({required this._service, required this._sessions});
  final AuthService _service;
  final AuthSessionSource _sessions;
  @override
  AuthenticationSnapshot get snapshot => _sessions.current;
  @override
  Stream<AuthenticationSnapshot> watchStatus() => _sessions.watchChanges();
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _service.signOut();
}
