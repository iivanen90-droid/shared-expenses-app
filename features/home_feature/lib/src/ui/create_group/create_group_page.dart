import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_feature/src/domain/entity/group_currency.dart';
import 'package:home_feature/src/ui/create_group/create_group_cubit.dart';
import 'package:home_feature/src/ui/create_group/create_group_state.dart';
import 'package:home_feature/src/ui/create_group/currency_picker.dart';
import 'package:home_feature/src/ui/create_group/group_emoji_picker.dart';
import 'package:router/router.dart';
import 'package:ui_kit/ui_kit.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<CreateGroupCubit>(
    create: (_) => DependencyProvider.get<CreateGroupCubit>(),
    child: const _CreateGroupForm(),
  );
}

class _CreateGroupForm extends StatefulWidget {
  const _CreateGroupForm();

  @override
  State<_CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends State<_CreateGroupForm> {
  final _nameKey = GlobalKey();
  final _currencyKey = GlobalKey();

  Future<void> _selectEmoji() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const GroupEmojiPicker(),
    );
    if (mounted && emoji != null) context.read<CreateGroupCubit>().selectEmoji(emoji);
  }

  Future<void> _selectCurrency(String? selectedCode) async {
    final currency = await showModalBottomSheet<GroupCurrency>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CurrencyPicker(selectedCode: selectedCode),
    );
    if (mounted && currency != null) context.read<CreateGroupCubit>().selectCurrency(currency);
  }

  void _scrollToFirstError(CreateGroupState state) {
    final participant = state.firstUnnamedParticipant;
    final key = switch (state) {
      CreateGroupState(nameMissing: true) => _nameKey,
      CreateGroupState(currency: null) => _currencyKey,
      _ when participant != null => GlobalObjectKey(participant.id),
      _ => null,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final field = key?.currentContext;
      if (field != null && field.mounted) Scrollable.ensureVisible(field);
    });
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<CreateGroupCubit, CreateGroupState>(
    listenWhen: (previous, current) =>
        previous.validationAttempts != current.validationAttempts || previous.groupId != current.groupId,
    listener: (context, state) {
      final id = state.groupId;
      if (id != null) {
        context.goTo(GroupCreatedRoute(groupId: id));
      } else {
        _scrollToFirstError(state);
      }
    },
    builder: (context, state) {
      final cubit = context.read<CreateGroupCubit>();
      final canEdit = state.canEdit;
      final showErrors = state.validationAttempts > 0;
      final currency = state.currency;
      return PopScope(
        canPop: canEdit,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const BackButtonIcon(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: canEdit ? () => context.goTo(const HomeRoute()) : null,
            ),
            title: Text(LocaleKeys.groupCreateTitle.tr(context: context)),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              key: const ValueKey('group_form_scroll'),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(LocaleKeys.groupName.tr(context: context), style: context.texts.title),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton.filledTonal(
                        tooltip: LocaleKeys.groupEmoji.tr(context: context),
                        onPressed: canEdit ? _selectEmoji : null,
                        icon: Text(state.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        key: _nameKey,
                        child: TextFormField(
                          key: const ValueKey('group_name'),
                          initialValue: state.name,
                          onChanged: cubit.changeName,
                          enabled: canEdit,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: LocaleKeys.groupNameHint.tr(context: context),
                            border: const OutlineInputBorder(),
                            errorText: showErrors && state.nameMissing
                                ? LocaleKeys.groupNameRequired.tr(context: context)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  KeyedSubtree(
                    key: _currencyKey,
                    child: OutlinedButton(
                      key: const ValueKey('group_currency'),
                      onPressed: canEdit ? () => _selectCurrency(currency?.code) : null,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: LocaleKeys.groupCurrency.tr(context: context),
                          errorText: showErrors && currency == null
                              ? LocaleKeys.groupCurrencyRequired.tr(context: context)
                              : null,
                        ),
                        child: Text(
                          currency == null
                              ? LocaleKeys.groupCurrencySelect.tr(context: context)
                              : '${currency.name(context.locale.languageCode)} (${currency.code})',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(LocaleKeys.groupParticipants.tr(context: context), style: context.texts.title),
                  for (final participant in state.participants)
                    Padding(
                      key: GlobalObjectKey(participant.id),
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        initialValue: participant.name,
                        onChanged: (name) => cubit.changeParticipantName(participant.id, name),
                        enabled: canEdit,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.groupParticipantName.tr(context: context),
                          border: const OutlineInputBorder(),
                          errorText: showErrors && participant.name.trim().isEmpty
                              ? LocaleKeys.groupParticipantRequired.tr(context: context)
                              : null,
                          suffixIcon: IconButton(
                            tooltip: LocaleKeys.groupRemoveParticipant.tr(context: context),
                            onPressed: canEdit ? () => cubit.removeParticipant(participant.id) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: canEdit ? cubit.addParticipant : null,
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(LocaleKeys.groupAddParticipant.tr(context: context)),
                    ),
                  ),
                  if (state.status == CreateGroupStatus.failed)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        LocaleKeys.groupSaveFailed.tr(context: context),
                        style: context.texts.body.copyWith(color: context.colors.error),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: canEdit ? cubit.create : null,
                    child: Text(
                      (state.status == CreateGroupStatus.saving ? LocaleKeys.groupSaving : LocaleKeys.groupCreate).tr(
                        context: context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
