import 'package:common/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';

part 'group_details_cubit.freezed.dart';

enum GroupDetailsStatus { loading, ready, missing, failed }

@freezed
abstract class GroupDetailsState with _$GroupDetailsState {
  const factory GroupDetailsState({@Default(GroupDetailsStatus.loading) GroupDetailsStatus status, HomeGroup? group}) =
      _GroupDetailsState;
}

final class GroupDetailsCubit extends SafeCubitWrapper<GroupDetailsState> {
  GroupDetailsCubit({required this._interactor}) : super(const GroupDetailsState());

  final HomeGroupsInteractor _interactor;

  Future<void> load(int id) async {
    emit(const GroupDetailsState());
    final result = await _interactor.find(id);
    result.match(
      (_) => emit(const GroupDetailsState(status: GroupDetailsStatus.failed)),
      (group) => emit(
        GroupDetailsState(status: group == null ? GroupDetailsStatus.missing : GroupDetailsStatus.ready, group: group),
      ),
    );
  }
}
