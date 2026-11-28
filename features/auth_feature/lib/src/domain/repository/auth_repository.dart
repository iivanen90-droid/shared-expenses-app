import 'package:core/core.dart';

abstract interface class AuthRepository {
  /// Initial page state, including an active session whose secure write failed.
  AuthenticationSnapshot get snapshot;

  /// Future SDK changes used internally to complete one sign-in Future.
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchChanges();

  /// Launch only; AuthInteractor waits for the confirmed result.
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
