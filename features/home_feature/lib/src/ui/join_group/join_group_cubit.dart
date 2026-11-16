import 'package:common/common.dart';
import 'package:home_feature/src/ui/join_group/join_group_state.dart';

final class JoinGroupCubit extends SafeCubitWrapper<JoinGroupState> {
  JoinGroupCubit() : super(const JoinGroupState());

  void updateInviteLink(String value) {
    emit(JoinGroupState(status: value.trim().isEmpty ? JoinGroupStatus.empty : JoinGroupStatus.ready));
  }

  void submit() {
    if (state.canSubmit) emit(const JoinGroupState(status: JoinGroupStatus.unavailable));
  }
}
