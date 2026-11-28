import 'dart:async';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_account_interactor.dart';
import 'package:main_shell_feature/src/ui/profile/profile_account_state.dart';

final class ProfileAccountCubit extends SafeCubitWrapper<ProfileAccountState> {
  ProfileAccountCubit({required this._interactor}) : super(const ProfileAccountState());
  final ProfileAccountInteractor _interactor;
  StreamSubscription<AuthenticationSnapshot>? _subscription;

  void initialize() {
    _publish(_interactor.snapshot.failure?.kind);
    _subscription ??= _interactor.watchStatus().listen((account) => _publish(account.failure?.kind));
  }

  void _publish(AuthenticationFailureKind? failure) {
    var status = state.status;
    if (status != ProfileAccountStatus.signingOut) {
      status = failure == null ? ProfileAccountStatus.initial : ProfileAccountStatus.error;
    }
    emit(ProfileAccountState(status: status, session: _interactor.snapshot.session, failure: failure));
  }

  Future<void> signOut() async {
    if (isClosed || state.status == ProfileAccountStatus.signingOut || state.session != AuthenticationStatus.signedIn) {
      return;
    }
    emit(ProfileAccountState(status: ProfileAccountStatus.signingOut, session: state.session));
    final result = await _interactor.signOut();
    result.match(
      (failure) => emit(
        ProfileAccountState(
          status: ProfileAccountStatus.error,
          session: _interactor.snapshot.session,
          failure: failure.kind,
        ),
      ),
      (_) => emit(const ProfileAccountState(session: AuthenticationStatus.signedOut)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
