import 'package:core/src/domain/failure/failure.dart';
import 'package:fpdart/fpdart.dart';

enum AuthenticationStatus { unconfigured, signedOut, signedIn }

enum AuthenticationFailureKind { configuration, connection, cancelled, storage }

final class AuthenticationProfile {
  const AuthenticationProfile({this.name, this.email});
  final String? name;
  final String? email;
  @override
  String toString() => 'AuthenticationProfile';
}

final class AuthenticationFailure extends Failure implements Exception {
  const AuthenticationFailure(this.kind);
  final AuthenticationFailureKind kind;
  @override
  String toString() => 'AuthenticationFailure(${kind.name})';
}

typedef AuthenticationSnapshot = ({AuthenticationStatus session, AuthenticationFailure? failure});

enum AuthSource { google }

/// SDK commands. launchSignIn opens the provider; the session source confirms sign-in.
abstract interface class AuthService {
  Future<void> initialize();
  Future<Either<AuthenticationFailure, Unit>> launchSignIn({required AuthSource source});
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
