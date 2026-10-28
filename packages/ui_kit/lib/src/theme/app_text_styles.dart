import 'package:flutter/material.dart';

final class AppTextStyles {
  const AppTextStyles({
    required this.heading,
    required this.title,
    required this.body,
    required this.label,
    required this.caption,
  });
  factory AppTextStyles.fromMaterial(TextTheme theme) => AppTextStyles(
    heading: theme.headlineSmall ?? const TextStyle(),
    title: theme.titleMedium ?? const TextStyle(),
    body: theme.bodyMedium ?? const TextStyle(),
    label: theme.labelLarge ?? const TextStyle(),
    caption: theme.bodySmall ?? const TextStyle(),
  );
  final TextStyle heading;
  final TextStyle title;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;
}
