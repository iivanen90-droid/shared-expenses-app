import 'package:core/core.dart';

abstract interface class AuthRepository {
  Future<Either<AuthenticationFailure, Unit>> signIn({required AuthSource source});
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
