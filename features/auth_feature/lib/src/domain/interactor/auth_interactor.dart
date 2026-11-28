import 'package:core/core.dart';
import 'package:auth_feature/src/domain/repository/auth_repository.dart';

abstract interface class AuthInteractor {
  Future<Either<AuthenticationFailure, Unit>> signIn({required AuthSource source});
  Future<Either<AuthenticationFailure, Unit>> signOut();
}

final class AuthInteractorImpl implements AuthInteractor {
  const AuthInteractorImpl({required this._repository});
  final AuthRepository _repository;
  @override
  Future<Either<AuthenticationFailure, Unit>> signIn({required AuthSource source}) =>
      _repository.signIn(source: source);
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _repository.signOut();
}
