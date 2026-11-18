import 'package:core/core.dart';
import 'package:auth_feature/src/domain/repository/auth_repository.dart';

abstract interface class AuthInteractor {
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus();
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}

final class AuthInteractorImpl implements AuthInteractor {
  const AuthInteractorImpl({required this._repository});
  final AuthRepository _repository;

  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => _repository.watchStatus();
  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() => _repository.signInWithGoogle();
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _repository.signOut();
}
