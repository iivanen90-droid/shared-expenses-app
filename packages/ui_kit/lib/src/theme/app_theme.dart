import 'package:flutter/material.dart';
import 'package:ui_kit/src/theme/app_color_scheme.dart';
import 'package:ui_kit/src/theme/app_text_styles.dart';

final class AppIcons {
  const AppIcons();
  IconData get retry => Icons.refresh;
}

final class AppTheme {
  const AppTheme({required this.material, required this.colors, required this.texts, required this.icons});
  factory AppTheme.main() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2));
    final material = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: scheme.surface);
    return AppTheme(
      material: material,
      colors: AppColorScheme.fromMaterial(material.colorScheme),
      texts: AppTextStyles.fromMaterial(material.textTheme),
      icons: const AppIcons(),
    );
  }
  final ThemeData material;
  final AppColorScheme colors;
  final AppTextStyles texts;
  final AppIcons icons;
}

class AppThemeProvider extends InheritedWidget {
  const AppThemeProvider({required this.theme, required super.child, super.key});
  final AppTheme theme;
  static AppTheme of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppThemeProvider>();
    if (provider == null) throw StateError('AppThemeProvider is missing.');
    return provider.theme;
  }

  @override
  bool updateShouldNotify(AppThemeProvider oldWidget) => theme != oldWidget.theme;
}

extension AppThemeContext on BuildContext {
  AppColorScheme get colors => AppThemeProvider.of(this).colors;
  AppTextStyles get texts => AppThemeProvider.of(this).texts;
  AppIcons get icons => AppThemeProvider.of(this).icons;
}
