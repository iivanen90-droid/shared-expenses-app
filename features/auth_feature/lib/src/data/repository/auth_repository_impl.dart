import 'package:core/core.dart';
import 'package:auth_feature/src/domain/repository/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this._service});
  final AuthService _service;

  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => _service.watchStatus();
  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() => _service.signInWithGoogle();
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _service.signOut();
}
