import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_feature/src/ui/join_group/join_group_cubit.dart';
import 'package:home_feature/src/ui/join_group/join_group_state.dart';
import 'package:ui_kit/ui_kit.dart';

class JoinGroupPage extends StatelessWidget {
  const JoinGroupPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<JoinGroupCubit>(
    create: (_) => DependencyProvider.get<JoinGroupCubit>(),
    child: const _JoinGroupView(),
  );
}

class _JoinGroupView extends StatelessWidget {
  const _JoinGroupView();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const CloseButton()),
    body: SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.link_rounded, color: context.colors.primary, size: 44),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(
                    LocaleKeys.joinGroupTitle.tr(context: context),
                    style: context.texts.heading,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.joinGroupInstructions.tr(context: context),
                  style: context.texts.body.copyWith(color: context.colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: context.read<JoinGroupCubit>().updateInviteLink,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.joinGroupLinkHint.tr(context: context),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                const _JoinGroupActions(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _JoinGroupActions extends StatelessWidget {
  const _JoinGroupActions();

  @override
  Widget build(BuildContext context) => BlocBuilder<JoinGroupCubit, JoinGroupState>(
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: state.canSubmit
              ? () {
                  FocusScope.of(context).unfocus();
                  context.read<JoinGroupCubit>().submit();
                }
              : null,
          child: Text(LocaleKeys.joinGroupAction.tr(context: context)),
        ),
        if (state.status == JoinGroupStatus.unavailable)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                LocaleKeys.joinGroupUnavailable.tr(context: context),
                style: context.texts.body,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    ),
  );
}
