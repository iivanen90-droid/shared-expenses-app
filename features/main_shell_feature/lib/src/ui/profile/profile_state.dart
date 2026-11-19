import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'profile_state.freezed.dart';

enum ProfileStatus { loading, ready, savingLanguage, signingOut, signedOut }

enum ProfileFailure { loading, language, logout }

@Freezed(toStringOverride: false)
abstract class ProfileState with _$ProfileState {
  const ProfileState._();
  const factory ProfileState({
    @Default(ProfileStatus.loading) ProfileStatus status,
    @Default(AuthenticationStatus.unconfigured) AuthenticationStatus session,
    AuthenticationProfile? profile,
    @Default(AppLanguage.en) AppLanguage language,
    ProfileFailure? failure,
  }) = _ProfileState;
  bool get busy => status != ProfileStatus.ready;
  @override
  String toString() => 'ProfileState(${status.name})';
}
