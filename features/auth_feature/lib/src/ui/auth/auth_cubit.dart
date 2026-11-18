import 'dart:async';

import 'package:auth_feature/src/domain/interactor/auth_interactor.dart';
import 'package:auth_feature/src/ui/auth/auth_state.dart';
import 'package:common/common.dart';
import 'package:core/core.dart';

final class AuthCubit extends SafeCubitWrapper<AuthState> {
  AuthCubit({required this._interactor}) : super(const AuthState());

  final AuthInteractor _interactor;
  StreamSubscription<Either<AuthenticationFailure, AuthenticationStatus>>? _subscription;
  bool _operationInFlight = false;

  void initialize() {
    _subscription ??= _interactor.watchStatus().listen(
      (result) {
        result.match((failure) => emit(state.copyWith(status: AuthStatus.ready, failure: failure.kind)), (session) {
          emit(
            AuthState(
              status: state.status == AuthStatus.signingOut ? AuthStatus.signingOut : AuthStatus.ready,
              session: session,
            ),
          );
        });
      },
      onError: (Object _, StackTrace _) =>
          emit(state.copyWith(status: AuthStatus.ready, failure: AuthenticationFailureKind.connection)),
    );
  }

  Future<void> signInWithGoogle() async {
    if (isClosed ||
        _operationInFlight ||
        state.status != AuthStatus.ready ||
        state.session != AuthenticationStatus.signedOut) {
      return;
    }
    _operationInFlight = true;
    emit(state.copyWith(status: AuthStatus.waitingForGoogle, failure: null));
    try {
      final result = await _interactor.signInWithGoogle();
      result.match((failure) => emit(state.copyWith(status: AuthStatus.ready, failure: failure.kind)), (_) {});
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> cancelSignIn() async {
    if (isClosed || state.status != AuthStatus.waitingForGoogle || _operationInFlight) return;
    _operationInFlight = true;
    emit(state.copyWith(status: AuthStatus.signingOut));
    try {
      final result = await _interactor.signOut();
      result.match(
        (failure) => emit(state.copyWith(status: AuthStatus.ready, failure: failure.kind)),
        (_) => emit(
          const AuthState(
            status: AuthStatus.ready,
            session: AuthenticationStatus.signedOut,
            failure: AuthenticationFailureKind.cancelled,
          ),
        ),
      );
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> signOut() async {
    if (isClosed || _operationInFlight || state.session != AuthenticationStatus.signedIn) return;
    _operationInFlight = true;
    emit(state.copyWith(status: AuthStatus.signingOut, failure: null));
    try {
      final result = await _interactor.signOut();
      result.match(
        (failure) => emit(state.copyWith(status: AuthStatus.ready, failure: failure.kind)),
        (_) => emit(const AuthState(status: AuthStatus.ready, session: AuthenticationStatus.signedOut)),
      );
    } finally {
      _operationInFlight = false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
