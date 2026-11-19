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

abstract interface class AuthService {
  AuthenticationProfile? get currentProfile;
  Future<void> initialize();
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus();
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle();
  Future<Either<AuthenticationFailure, Unit>> signOut();
}
