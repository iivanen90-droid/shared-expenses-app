import 'package:common/common.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';
import 'package:home_feature/src/ui/group/group_details_state.dart';

final class GroupDetailsCubit extends SafeCubitWrapper<GroupDetailsState> {
  GroupDetailsCubit({required this._interactor}) : super(const GroupDetailsState());

  final HomeGroupsInteractor _interactor;

  Future<void> initialize(int groupId) async {
    emit(const GroupDetailsState());
    final result = await _interactor.getGroupById(groupId);
    result.match(
      (_) => emit(const GroupDetailsState(status: GroupDetailsStatus.failed)),
      (group) => emit(
        GroupDetailsState(status: group == null ? GroupDetailsStatus.missing : GroupDetailsStatus.ready, group: group),
      ),
    );
  }
}
