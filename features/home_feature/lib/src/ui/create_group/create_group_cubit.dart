import 'package:common/common.dart';
import 'package:home_feature/src/domain/entity/group_currency.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';
import 'package:home_feature/src/ui/create_group/create_group_state.dart';

final class CreateGroupCubit extends SafeCubitWrapper<CreateGroupState> {
  CreateGroupCubit({required this._interactor}) : super(const CreateGroupState());

  final HomeGroupsInteractor _interactor;

  void changeName(String name) => _edit(state.copyWith(name: name));
  void selectEmoji(String emoji) => _edit(state.copyWith(emoji: emoji));
  void selectCurrency(GroupCurrency currency) => _edit(state.copyWith(currency: currency));

  void addParticipant() =>
      _edit(state.copyWith(participants: List.unmodifiable([...state.participants, (id: Object(), name: '')])));

  void changeParticipantName(Object id, String name) => _edit(
    state.copyWith(
      participants: List.unmodifiable([
        for (final participant in state.participants)
          if (participant.id == id) (id: id, name: name) else participant,
      ]),
    ),
  );

  void removeParticipant(Object id) => _edit(
    state.copyWith(
      participants: List.unmodifiable([
        for (final participant in state.participants)
          if (participant.id != id) participant,
      ]),
    ),
  );

  void _edit(CreateGroupState draft) {
    if (state.canEdit) emit(draft);
  }

  Future<void> create() async {
    if (isClosed || !state.canEdit) return;
    final draft = state;
    final currency = draft.currency;
    if (draft.nameMissing || currency == null || draft.firstUnnamedParticipant != null) {
      emit(draft.copyWith(showValidationErrors: true));
      return;
    }
    emit(draft.copyWith(status: CreateGroupStatus.saving));
    final result = await _interactor.create((
      name: draft.name.trim(),
      emoji: draft.emoji,
      currencyCode: currency.code,
      participants: [for (final participant in draft.participants) participant.name.trim()],
    ));
    result.match(
      (_) => emit(draft.copyWith(status: CreateGroupStatus.failed)),
      (saved) => emit(draft.copyWith(status: CreateGroupStatus.created, groupId: saved.id)),
    );
  }
}
