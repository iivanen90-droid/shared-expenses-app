import 'package:core/core.dart';

abstract interface class AuthRepository {
  AuthenticationSnapshot get snapshot;
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchChanges();
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
