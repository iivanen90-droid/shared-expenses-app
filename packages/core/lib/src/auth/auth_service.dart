import 'package:core/src/domain/failure/failure.dart';
import 'package:fpdart/fpdart.dart';

enum AuthenticationStatus { unconfigured, signedOut, signedIn }

enum AuthenticationFailureKind { configuration, connection, cancelled, storage }

final class AuthenticationFailure extends Failure implements Exception {
  const AuthenticationFailure(this.kind);
  final AuthenticationFailureKind kind;
  @override
  String toString() => 'AuthenticationFailure(${kind.name})';
}

typedef AuthenticationSnapshot = ({AuthenticationStatus session, AuthenticationFailure? failure});

abstract interface class AuthService {
  AuthenticationSnapshot get snapshot;
  Future<void> initialize();
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus({bool replay = true});
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
