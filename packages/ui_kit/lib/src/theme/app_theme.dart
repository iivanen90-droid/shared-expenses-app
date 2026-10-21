import 'package:material_ui/material_ui.dart';

final class AppColorScheme {
  const AppColorScheme({required this.primary});
  final Color primary;
}

final class AppTextStyles {
  const AppTextStyles({required this.title});
  final TextStyle title;
}

final class AppIcons {
  const AppIcons();
  IconData get retry => Icons.refresh;
}

final class AppTheme {
  const AppTheme({required this.material, required this.colors, required this.texts, required this.icons});
  factory AppTheme.main() {
    final material = ThemeData(colorSchemeSeed: const Color(0xFF1976D2));
    return AppTheme(
      material: material,
      colors: AppColorScheme(primary: material.colorScheme.primary),
      texts: AppTextStyles(title: material.textTheme.titleMedium ?? const TextStyle()),
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
