import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/ui/home/add_group_sheet.dart';
import 'package:home_feature/src/ui/home/state/home_cubit.dart';
import 'package:router/router.dart';
import 'package:ui_kit/ui_kit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<HomeCubit>(
    create: (_) => DependencyProvider.get<HomeCubit>()..initialize(),
    child: const _HomeView(),
  );
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _openSheet(BuildContext context) async {
    final start = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          AddGroupSheet(onStart: () => Navigator.of(sheetContext).pop(true), onJoin: _joinExistingGroup),
    );
    if (context.mounted && start == true) context.goTo(const CreateGroupRoute());
  }

  void _joinExistingGroup() {
    // The invitation flow will be connected here when it exists.
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Semantics(
              identifier: 'home_title',
              header: true,
              child: Row(
                children: [
                  Assets.icons.startup.svg(
                    width: 32,
                    height: 32,
                    excludeFromSemantics: true,
                    colorFilter: ColorFilter.mode(context.colors.primary, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      LocaleKeys.brandName.tr(context: context),
                      style: context.texts.heading.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) => switch (state.status) {
                HomeStatus.loading => const Center(child: CircularProgressIndicator()),
                HomeStatus.failed => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(LocaleKeys.groupsLoadFailed.tr(context: context)),
                      TextButton(
                        onPressed: context.read<HomeCubit>().retry,
                        child: Text(LocaleKeys.retry.tr(context: context)),
                      ),
                    ],
                  ),
                ),
                HomeStatus.loaded when state.groups.isEmpty => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      LocaleKeys.noGroups.tr(context: context),
                      textAlign: TextAlign.center,
                      style: context.texts.body.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ),
                HomeStatus.loaded => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.groups.length,
                  itemBuilder: (_, index) => _GroupCard(group: state.groups[index]),
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Center(
              child: Semantics(
                identifier: 'home_new_tricount',
                child: FilledButton.tonalIcon(
                  onPressed: () => _openSheet(context),
                  icon: const Icon(Icons.add),
                  label: Text(LocaleKeys.newTricount.tr(context: context), textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final HomeGroup group;

  @override
  Widget build(BuildContext context) => Card.filled(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ExcludeSemantics(child: Text(group.emoji, style: context.texts.heading)),
      title: Text(group.name, style: context.texts.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.goTo(GroupDetailsRoute(groupId: group.id)),
    ),
  );
}
