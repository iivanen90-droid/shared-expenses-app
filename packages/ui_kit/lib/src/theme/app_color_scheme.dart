import 'package:flutter/material.dart';

final class AppColorScheme {
  const AppColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.error,
    required this.onError,
  });
  factory AppColorScheme.fromMaterial(ColorScheme scheme) => AppColorScheme(
    primary: scheme.primary,
    onPrimary: scheme.onPrimary,
    surface: scheme.surface,
    onSurface: scheme.onSurface,
    onSurfaceVariant: scheme.onSurfaceVariant,
    outline: scheme.outline,
    error: scheme.error,
    onError: scheme.onError,
  );
  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color error;
  final Color onError;
}
