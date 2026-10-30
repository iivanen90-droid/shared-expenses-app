import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/app.dart';

Future<void> run({required EnvironmentType environment}) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode && !binding.semanticsEnabled) binding.ensureSemantics();
  MainDependenciesModuleResolver.register(environment: environment);
  try {
    await DependencyProvider.get<ApplicationInitializer>().initialize();
  } on Object catch (error, stackTrace) {
    DependencyProvider.get<CrashReportingService>().recordError(error, stackTrace, fatal: true);
  }
  await EasyLocalization.ensureInitialized();
  // Splash retains its existing retry path if startup fails.
  runApp(const LocalizationsWrapper(child: App()));
}
