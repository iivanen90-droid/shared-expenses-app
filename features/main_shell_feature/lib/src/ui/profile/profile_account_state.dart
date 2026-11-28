import 'package:core/core.dart';

enum ProfileAccountStatus { initial, signingOut, error }

final class ProfileAccountState {
  const ProfileAccountState({
    this.status = ProfileAccountStatus.initial,
    this.session = AuthenticationStatus.unconfigured,
    this.failure,
  });
  final ProfileAccountStatus status;
  final AuthenticationStatus session;
  final AuthenticationFailureKind? failure;
}
