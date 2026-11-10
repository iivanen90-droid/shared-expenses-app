import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class GroupEmojiPicker extends StatelessWidget {
  const GroupEmojiPicker({required this.selected, super.key});

  final String selected;

  static const _emojis = [
    '💸',
    '🏖️',
    '🏔️',
    '✈️',
    '🚆',
    '🚗',
    '🏠',
    '🎉',
    '🍕',
    '☕',
    '🍿',
    '🎁',
    '🎮',
    '🎵',
    '⚽',
    '🧳',
    '🏕️',
    '🛍️',
    '📚',
    '💼',
    '🐶',
    '🌻',
    '❤️',
    '⭐',
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(LocaleKeys.groupEmoji.tr(context: context), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Flexible(
            child: GridView.extent(
              shrinkWrap: true,
              maxCrossAxisExtent: 72,
              children: [
                for (final emoji in _emojis)
                  Semantics(
                    selected: emoji == selected,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, emoji),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
