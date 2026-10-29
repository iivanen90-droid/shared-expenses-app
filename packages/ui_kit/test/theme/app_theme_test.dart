import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  testWidgets('public theme styles and colors render in Flutter Material widgets', (tester) async {
    final theme = AppTheme.main();
    await tester.pumpWidget(
      AppThemeProvider(
        theme: theme,
        child: MaterialApp(
          theme: theme.material,
          home: const Scaffold(body: _ThemeSample()),
        ),
      ),
    );
    final title = tester.widget<Text>(find.text('Title'));
    final context = tester.element(find.text('Title'));
    expect(title.style?.color, theme.colors.primary);
    expect(title.style?.fontSize, theme.texts.title.fontSize);
    expect(Theme.of(context).colorScheme.primary, context.colors.primary);
    expect(Theme.of(context).scaffoldBackgroundColor, context.colors.surface);
    for (final text in ['Heading', 'Body', 'Label', 'Caption']) {
      expect(tester.widget<Text>(find.text(text)).style, isNotNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('dependent widgets update when an inherited theme is replaced', (tester) async {
    final original = AppTheme.main();
    final themes = ValueNotifier(original);
    addTearDown(themes.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<AppTheme>(
          valueListenable: themes,
          builder: (_, theme, child) => AppThemeProvider(theme: theme, child: child ?? const SizedBox.shrink()),
          child: const _ThemeSample(),
        ),
      ),
    );
    final replacement = _replacementTheme(original);
    themes.value = replacement;
    await tester.pump();
    final title = tester.widget<Text>(find.text('Title'));
    expect(title.style?.color, replacement.colors.primary);
    expect(title.style?.color, isNot(original.colors.primary));
    expect(title.style?.fontSize, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the closest theme provider takes precedence', (tester) async {
    final outer = AppTheme.main();
    final inner = _replacementTheme(outer);
    await tester.pumpWidget(
      MaterialApp(
        home: AppThemeProvider(
          theme: outer,
          child: AppThemeProvider(theme: inner, child: const _ThemeSample()),
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('Title')).style?.color, inner.colors.primary);
    expect(tester.widget<Text>(find.text('Title')).style?.fontSize, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reading the theme without a provider reports a clear error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ThemeSample()));
    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect(error.toString(), contains('AppThemeProvider is missing'));
  });
}

AppTheme _replacementTheme(AppTheme base) {
  final material = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
    textTheme: base.material.textTheme.copyWith(titleMedium: base.texts.title.copyWith(fontSize: 30)),
  );
  return AppTheme(
    material: material,
    colors: AppColorScheme.fromMaterial(material.colorScheme),
    texts: AppTextStyles.fromMaterial(material.textTheme),
    icons: base.icons,
  );
}

class _ThemeSample extends StatelessWidget {
  const _ThemeSample();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.surface,
    child: Column(
      children: [
        Text('Heading', style: context.texts.heading),
        Text('Title', style: context.texts.title.copyWith(color: context.colors.primary)),
        Text('Body', style: context.texts.body),
        Text('Label', style: context.texts.label),
        Text('Caption', style: context.texts.caption),
      ],
    ),
  );
}
