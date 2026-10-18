import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:router/router.dart';
import 'package:ui_kit/ui_kit.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = GoRouterConfig.create();
  final _theme = AppTheme.main();
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppThemeProvider(
    theme: _theme,
    child: MaterialApp.router(
      onGenerateTitle: (_) => LocaleKeys.appTitle.tr(),
      debugShowCheckedModeBanner: false,
      theme: _theme.material,
      routerConfig: _router,
      localizationsDelegates: context.appLocalizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    ),
  );
}
