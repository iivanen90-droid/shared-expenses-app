import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show SemanticsHandle;
import 'package:mobile/app.dart';

// Keep debug semantics enabled for the application lifetime, including bootstrap retries.
SemanticsHandle? _debugSemanticsHandle;

Future<void> run({required EnvironmentType environment}) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode && !binding.semanticsEnabled) _debugSemanticsHandle ??= binding.ensureSemantics();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  MainDependenciesModuleResolver.register(environment: environment);
  final fallback = binding.platformDispatcher.locale.languageCode == 'uk' ? AppLanguage.uk : AppLanguage.en;
  AppLanguage language = fallback;
  try {
    language = await DependencyProvider.get<LanguagePreferences>().load(fallback: fallback);
  } on Object catch (error, stackTrace) {
    DependencyProvider.get<CrashReportingService>().recordError(error, stackTrace);
  }
  await EasyLocalization.ensureInitialized();
  try {
    await DependencyProvider.get<ApplicationInitializer>().initialize();
  } on Object catch (error, stackTrace) {
    DependencyProvider.get<CrashReportingService>().recordError(error, stackTrace, fatal: true);
  }
  // Splash retains its existing retry path if startup fails.
  runApp(LocalizationsWrapper(initialLocale: Locale(language.name), child: const App()));
}
