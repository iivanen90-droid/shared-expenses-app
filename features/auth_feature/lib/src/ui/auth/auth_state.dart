import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

enum AuthStatus { loading, ready, waitingForGoogle, signingOut }

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.loading) AuthStatus status,
    @Default(AuthenticationStatus.unconfigured) AuthenticationStatus session,
    AuthenticationFailureKind? failure,
  }) = _AuthState;
}
