import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_feature/src/ui/create_group/create_group_cubit.dart';
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
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _participants = <TextEditingController>[];
  GroupCurrency? _currency;
  String _emoji = '💸';

  @override
  void dispose() {
    _name.dispose();
    for (final participant in _participants) {
      participant.dispose();
    }
    super.dispose();
  }

  String? _requiredText(String? value, String errorKey) =>
      (value ?? '').trim().isEmpty ? errorKey.tr(context: context) : null;

  void _submit() {
    final form = _form.currentState;
    if (form == null) return;
    final invalid = form.validateGranularly();
    if (invalid.isNotEmpty) {
      final first = invalid.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (first.mounted) Scrollable.ensureVisible(first.context);
      });
      return;
    }
    final currency = _currency;
    if (currency == null) return;
    context.read<CreateGroupCubit>().create((
      name: _name.text.trim(),
      emoji: _emoji,
      currencyCode: currency.code,
      participants: [for (final participant in _participants) participant.text.trim()],
    ));
  }

  Future<void> _selectEmoji() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => GroupEmojiPicker(selected: _emoji),
    );
    if (mounted && emoji != null) setState(() => _emoji = emoji);
  }

  Future<void> _selectCurrency(FormFieldState<GroupCurrency> field) async {
    final currency = await Navigator.of(context)
        .push<GroupCurrency>(MaterialPageRoute(builder: (_) => CurrencyPicker(selectedCode: _currency?.code)));
    if (!mounted || !field.mounted || currency == null) return;
    setState(() => _currency = currency);
    field.didChange(currency);
  }

  void _removeParticipant(TextEditingController participant) {
    setState(() => _participants.remove(participant));
    WidgetsBinding.instance.addPostFrameCallback((_) => participant.dispose());
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<CreateGroupCubit, CreateGroupState>(
    listener: (context, state) {
      final id = state.groupId;
      if (state.status == CreateGroupStatus.created && id != null) {
        context.goTo(GroupCreatedRoute(groupId: id));
      }
    },
    builder: (context, state) {
      final saving = state.status == CreateGroupStatus.saving;
      return PopScope(
        canPop: !saving,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: saving ? null : () => context.goTo(const HomeRoute())),
            title: Text(LocaleKeys.groupCreateTitle.tr(context: context)),
          ),
          body: SafeArea(
            child: Form(
              key: _form,
              child: SingleChildScrollView(
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
                          onPressed: saving ? null : _selectEmoji,
                          icon: Text(_emoji, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('group_name'),
                            controller: _name,
                            enabled: !saving,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: LocaleKeys.groupNameHint.tr(context: context),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) => _requiredText(value, LocaleKeys.groupNameRequired),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormField<GroupCurrency>(
                      initialValue: _currency,
                      validator: (value) =>
                          value == null ? LocaleKeys.groupCurrencyRequired.tr(context: context) : null,
                      builder: (field) {
                        final currency = field.value;
                        return OutlinedButton(
                          key: const ValueKey('group_currency'),
                          onPressed: saving ? null : () => _selectCurrency(field),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: LocaleKeys.groupCurrency.tr(context: context),
                              errorText: field.errorText,
                            ),
                            child: Text(
                              currency == null
                                  ? LocaleKeys.groupCurrencySelect.tr(context: context)
                                  : '${currency.name(context.locale)} (${currency.code})',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(LocaleKeys.groupParticipants.tr(context: context), style: context.texts.title),
                    for (final participant in _participants)
                      Padding(
                        key: ObjectKey(participant),
                        padding: const EdgeInsets.only(top: 8),
                        child: TextFormField(
                          controller: participant,
                          enabled: !saving,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.groupParticipantName.tr(context: context),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: LocaleKeys.groupRemoveParticipant.tr(context: context),
                              onPressed: saving ? null : () => _removeParticipant(participant),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ),
                          validator: (value) => _requiredText(value, LocaleKeys.groupParticipantRequired),
                        ),
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: saving ? null : () => setState(() => _participants.add(TextEditingController())),
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
                      onPressed: saving ? null : _submit,
                      child: Text((saving ? LocaleKeys.groupSaving : LocaleKeys.groupCreate).tr(context: context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
