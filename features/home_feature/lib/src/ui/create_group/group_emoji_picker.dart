import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class GroupEmojiPicker extends StatelessWidget {
  const GroupEmojiPicker({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(LocaleKeys.groupEmoji.tr(context: context), style: context.texts.heading),
        const SizedBox(height: 8),
        EmojiPicker(
          onEmojiSelected: (_, emoji) => Navigator.pop(context, emoji.emoji),
          config: Config(
            height: 240,
            locale: context.locale,
            emojiViewConfig: EmojiViewConfig(backgroundColor: context.colors.surface),
            categoryViewConfig: CategoryViewConfig(
              backgroundColor: context.colors.surface,
              indicatorColor: context.colors.primary,
              iconColor: context.colors.onSurfaceVariant,
              iconColorSelected: context.colors.primary,
              recentTabBehavior: RecentTabBehavior.NONE,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
          ),
        ),
      ],
    ),
  );
}
