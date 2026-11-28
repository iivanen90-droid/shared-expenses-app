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
  /// Current session and persistence failure; reading it does not start a subscription.
  AuthenticationSnapshot get snapshot;
  Future<void> initialize();

  /// Future changes only. Read snapshot when opening a page; old failures are not replayed.
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus();
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
