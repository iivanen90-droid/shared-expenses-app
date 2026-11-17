import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:router/router.dart';
import 'package:ui_kit/ui_kit.dart';

class GroupCreatedPage extends StatelessWidget {
  const GroupCreatedPage({required this.groupId, super.key});

  final int groupId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: context.colors.primary, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        LocaleKeys.groupCreated.tr(context: context),
                        textAlign: TextAlign.center,
                        style: context.texts.heading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.goTo(GroupDetailsRoute(groupId: groupId)),
              child: Text(LocaleKeys.groupGoTo.tr(context: context)),
            ),
          ],
        ),
      ),
    ),
  );
}
