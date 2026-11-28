import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

enum AuthStatus { initial, loading, cancelling, error, authenticated }

@freezed
abstract class AuthState with _$AuthState {
  const AuthState._();
  const factory AuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    @Default(AuthenticationStatus.unconfigured) AuthenticationStatus session,
    AuthenticationFailureKind? failure,
  }) = _AuthState;

  bool get isBusy => status == AuthStatus.loading || status == AuthStatus.cancelling;
  bool get canSignIn => !isBusy && session == AuthenticationStatus.signedOut;
}
