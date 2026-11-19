import 'dart:async';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_interactor.dart';
import 'package:main_shell_feature/src/domain/repository/profile_repository.dart';
import 'package:main_shell_feature/src/ui/profile/profile_state.dart';

final class ProfileCubit extends SafeCubitWrapper<ProfileState> {
  ProfileCubit({required this._interactor}) : super(const ProfileState());
  final ProfileInteractor _interactor;
  StreamSubscription<Either<AuthenticationFailure, ProfileSnapshot>>? _subscription;
  void initialize(AppLanguage language) {
    if (_subscription != null || isClosed) return;
    emit(state.copyWith(language: language));
    _subscription = _interactor.watch().listen((result) {
      result.match(
        (_) => emit(
          state.copyWith(
            failure: ProfileFailure.loading,
            status: state.status == ProfileStatus.loading ? ProfileStatus.ready : state.status,
          ),
        ),
        (snapshot) => emit(
          state.copyWith(
            session: snapshot.session,
            profile: snapshot.profile,
            status: state.status == ProfileStatus.loading ? ProfileStatus.ready : state.status,
          ),
        ),
      );
    });
  }

  Future<void> changeLanguage(AppLanguage language) async {
    if (isClosed || state.busy || state.language == language) return;
    emit(state.copyWith(status: ProfileStatus.savingLanguage, failure: null));
    final result = await _interactor.saveLanguage(language);
    final saved = result.isRight();
    emit(
      state.copyWith(
        status: ProfileStatus.ready,
        language: saved ? language : state.language,
        failure: saved ? null : ProfileFailure.language,
      ),
    );
  }

  Future<void> signOut() async {
    if (isClosed || state.busy || state.session != AuthenticationStatus.signedIn) return;
    emit(state.copyWith(status: ProfileStatus.signingOut, failure: null));
    final result = await _interactor.signOut();
    result.match(
      (_) => emit(state.copyWith(status: ProfileStatus.ready, failure: ProfileFailure.logout)),
      (_) =>
          emit(state.copyWith(status: ProfileStatus.signedOut, session: AuthenticationStatus.signedOut, profile: null)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
