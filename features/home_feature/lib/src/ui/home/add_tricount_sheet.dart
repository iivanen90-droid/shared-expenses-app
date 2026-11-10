import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AddTricountSheet extends StatelessWidget {
  const AddTricountSheet({required this.onStart, required this.onJoin, super.key});

  final VoidCallback onStart;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Semantics(identifier: 'add_tricount_close', child: const CloseButton()),
                Expanded(
                  child: Semantics(
                    identifier: 'add_tricount_title',
                    header: true,
                    child: Text(
                      LocaleKeys.addTricount.tr(context: context),
                      style: context.texts.heading,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            _TricountAction(
              identifier: 'add_tricount_start',
              icon: Icons.add_rounded,
              iconBackground: colors.primaryContainer,
              iconForeground: colors.onPrimaryContainer,
              title: LocaleKeys.startNewTricount.tr(context: context),
              description: LocaleKeys.startNewTricountDescription.tr(context: context),
              onTap: onStart,
            ),
            const SizedBox(height: 8),
            _TricountAction(
              identifier: 'add_tricount_join',
              icon: Icons.link_rounded,
              iconBackground: colors.tertiaryContainer,
              iconForeground: colors.onTertiaryContainer,
              title: LocaleKeys.joinExistingTricount.tr(context: context),
              description: LocaleKeys.joinExistingTricountDescription.tr(context: context),
              onTap: onJoin,
            ),
          ],
        ),
      ),
    );
  }
}

class _TricountAction extends StatelessWidget {
  const _TricountAction({
    required this.identifier,
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String identifier;
  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card.filled(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Semantics(
      identifier: identifier,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: iconBackground, foregroundColor: iconForeground, child: Icon(icon)),
        title: Text(title, style: context.texts.title),
        subtitle: Text(description, style: context.texts.caption.copyWith(color: context.colors.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}
