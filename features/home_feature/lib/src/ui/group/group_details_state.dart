import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';

part 'group_details_state.freezed.dart';

enum GroupDetailsStatus { loading, ready, missing, failed }

@freezed
abstract class GroupDetailsState with _$GroupDetailsState {
  const factory GroupDetailsState({@Default(GroupDetailsStatus.loading) GroupDetailsStatus status, HomeGroup? group}) =
      _GroupDetailsState;
}
