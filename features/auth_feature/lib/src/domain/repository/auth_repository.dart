import 'package:core/core.dart';

abstract interface class AuthRepository {
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus();
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
