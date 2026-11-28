import 'package:auth_feature/src/domain/interactor/auth_interactor.dart';
import 'package:auth_feature/src/domain/interactor/auth_session_interactor.dart';
import 'package:auth_feature/src/ui/auth/auth_state.dart';
import 'package:common/common.dart';
import 'package:core/core.dart';

final class AuthCubit extends SafeCubitWrapper<AuthState> {
  AuthCubit({required this._interactor, required this._sessions}) : super(const AuthState());
  final AuthInteractor _interactor;
  final AuthSessionInteractor _sessions;

  void initialize() {
    final current = _sessions.current;
    var status = AuthStatus.initial;
    if (current.session == AuthenticationStatus.signedIn) status = AuthStatus.authenticated;
    if (current.failure != null) status = AuthStatus.error;
    emit(AuthState(status: status, session: current.session, failure: current.failure?.kind));
  }

  Future<void> signInWithGoogle() async {
    if (isClosed || !state.canSignIn) return;
    emit(state.copyWith(status: AuthStatus.loading, failure: null));
    final result = await _interactor.signIn(source: AuthSource.google);
    if (isClosed || state.status == AuthStatus.cancelling) return;
    result.match(
      _showFailure,
      (_) => emit(AuthState(status: AuthStatus.authenticated, session: _sessions.current.session)),
    );
  }

  Future<void> cancelSignIn() async {
    if (isClosed || state.status != AuthStatus.loading) return;
    emit(state.copyWith(status: AuthStatus.cancelling));
    final result = await _interactor.signOut();
    result.match(
      _showFailure,
      (_) => emit(AuthState(session: _sessions.current.session, failure: AuthenticationFailureKind.cancelled)),
    );
  }

  void _showFailure(AuthenticationFailure failure) => emit(
    AuthState(
      status: failure.kind == AuthenticationFailureKind.cancelled ? AuthStatus.initial : AuthStatus.error,
      session: _sessions.current.session,
      failure: failure.kind,
    ),
  );

  @override
  Future<void> close() async {
    if (isClosed) return;
    final cancelPending = state.isBusy;
    await super.close();
    if (cancelPending) await _interactor.signOut();
  }
}
