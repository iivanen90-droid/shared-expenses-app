import 'package:core/core.dart';

abstract interface class ProfileAccountRepository {
  AuthenticationSnapshot get snapshot;
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
