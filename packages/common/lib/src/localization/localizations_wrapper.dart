import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class LocalizationsWrapper extends StatelessWidget {
  const LocalizationsWrapper({required this.child, this.assetLoader = const RootBundleAssetLoader(), super.key});
  static const supportedLocales = [Locale('uk'), Locale('en')];
  static const fallbackLocale = Locale('uk');
  final Widget child;
  final AssetLoader assetLoader;
  @override
  Widget build(BuildContext context) => EasyLocalization(
    supportedLocales: supportedLocales,
    startLocale: fallbackLocale,
    fallbackLocale: fallbackLocale,
    path: 'packages/common/lib/src/localization/langs',
    assetLoader: assetLoader,
    child: child,
  );
}

// Standalone UI packages have localization types distinct from the legacy SDK delegates.
extension AppLocalizationContext on BuildContext {
  List<LocalizationsDelegate<dynamic>> get appLocalizationDelegates => [
    ...GlobalMaterialLocalizations.delegates,
    ...localizationDelegates,
  ];
}
