import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class LocalizationsWrapper extends StatelessWidget {
  const LocalizationsWrapper({required this.child, this.assetLoader = const RootBundleAssetLoader(), super.key});
  static const supportedLocales = [Locale('en'), Locale('uk')];
  static const fallbackLocale = Locale('en');
  final Widget child;
  final AssetLoader assetLoader;
  @override
  Widget build(BuildContext context) => EasyLocalization(
    supportedLocales: supportedLocales,
    fallbackLocale: fallbackLocale,
    useFallbackTranslations: true,
    path: 'packages/common/lib/src/localization/langs',
    assetLoader: assetLoader,
    child: child,
  );
}

extension AppLocalizationContext on BuildContext {
  List<LocalizationsDelegate<dynamic>> get appLocalizationDelegates => localizationDelegates;
}
