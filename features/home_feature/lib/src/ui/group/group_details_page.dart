import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_feature/src/ui/group/group_details_cubit.dart';
import 'package:home_feature/src/ui/group/group_details_state.dart';
import 'package:ui_kit/ui_kit.dart';

class GroupDetailsPage extends StatelessWidget {
  const GroupDetailsPage({required this.groupId, super.key});

  final int groupId;

  @override
  Widget build(BuildContext context) => BlocProvider<GroupDetailsCubit>(
    key: ValueKey(groupId),
    create: (_) => DependencyProvider.get<GroupDetailsCubit>()..initialize(groupId),
    child: BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
      builder: (context, state) {
        final group = state.group;
        return Scaffold(
          appBar: AppBar(title: Text(group?.name ?? LocaleKeys.groupDetailsTitle.tr(context: context))),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: switch (state.status) {
                  GroupDetailsStatus.loading => const CircularProgressIndicator(),
                  GroupDetailsStatus.missing => Text(LocaleKeys.groupMissing.tr(context: context)),
                  GroupDetailsStatus.failed => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(LocaleKeys.groupLoadFailed.tr(context: context)),
                      TextButton(
                        onPressed: () => context.read<GroupDetailsCubit>().initialize(groupId),
                        child: Text(LocaleKeys.retry.tr(context: context)),
                      ),
                    ],
                  ),
                  GroupDetailsStatus.ready => Semantics(
                    identifier: 'group_details',
                    child: Text(group?.emoji ?? '', style: context.texts.heading),
                  ),
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}
