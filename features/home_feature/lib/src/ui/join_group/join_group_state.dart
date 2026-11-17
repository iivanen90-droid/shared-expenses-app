import 'package:freezed_annotation/freezed_annotation.dart';

part 'join_group_state.freezed.dart';

enum JoinGroupStatus { empty, ready, unavailable }

@freezed
abstract class JoinGroupState with _$JoinGroupState {
  const JoinGroupState._();

  const factory JoinGroupState({@Default(JoinGroupStatus.empty) JoinGroupStatus status}) = _JoinGroupState;

  bool get canSubmit => status != JoinGroupStatus.empty;
}
