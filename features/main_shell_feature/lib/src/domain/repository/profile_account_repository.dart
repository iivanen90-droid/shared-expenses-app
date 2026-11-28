import 'package:core/core.dart';

abstract interface class ProfileAccountRepository {
  AuthenticationSnapshot get snapshot;
  Stream<AuthenticationSnapshot> watchStatus();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
