import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_feature/src/domain/entity/group_currency.dart';

part 'create_group_state.freezed.dart';

enum CreateGroupStatus { idle, saving, failed, created }

typedef ParticipantDraft = ({Object id, String name});

@Freezed(makeCollectionsUnmodifiable: false)
abstract class CreateGroupState with _$CreateGroupState {
  const CreateGroupState._();

  const factory CreateGroupState({
    @Default('\u{1f4b8}') String emoji,
    @Default('') String name,
    GroupCurrency? currency,
    @Default(<ParticipantDraft>[]) List<ParticipantDraft> participants,
    @Default(0) int validationAttempts,
    @Default(CreateGroupStatus.idle) CreateGroupStatus status,
    int? groupId,
  }) = _CreateGroupState;

  bool get nameMissing => name.trim().isEmpty;
  bool get canEdit => status != CreateGroupStatus.saving && status != CreateGroupStatus.created;
  ParticipantDraft? get firstUnnamedParticipant =>
      participants.where((participant) => participant.name.trim().isEmpty).firstOrNull;
}
