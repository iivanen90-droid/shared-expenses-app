import 'package:common/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';

part 'create_group_cubit.freezed.dart';

enum CreateGroupStatus { idle, saving, failed, created }

@freezed
abstract class CreateGroupState with _$CreateGroupState {
  const factory CreateGroupState({@Default(CreateGroupStatus.idle) CreateGroupStatus status, int? groupId}) =
      _CreateGroupState;
}

final class CreateGroupCubit extends SafeCubitWrapper<CreateGroupState> {
  CreateGroupCubit({required this._interactor}) : super(const CreateGroupState());

  final HomeGroupsInteractor _interactor;

  Future<void> create(NewGroup group) async {
    if (isClosed || state.status == CreateGroupStatus.saving || state.status == CreateGroupStatus.created) return;
    emit(const CreateGroupState(status: CreateGroupStatus.saving));
    final result = await _interactor.create(group);
    result.match(
      (_) => emit(const CreateGroupState(status: CreateGroupStatus.failed)),
      (saved) => emit(CreateGroupState(status: CreateGroupStatus.created, groupId: saved.id)),
    );
  }
}
