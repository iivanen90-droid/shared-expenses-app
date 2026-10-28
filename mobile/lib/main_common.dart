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

Future<void> run({
  required EnvironmentType environment,
  ApplicationInitializer? initializer,
  void Function(Widget)? appRunner,
}) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) _debugSemanticsHandle ??= binding.ensureSemantics();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  MainDependenciesModuleResolver.register(environment: environment, initializer: initializer);
  try {
    await DependencyProvider.get<ApplicationInitializer>().initialize();
  } on Object catch (error, stackTrace) {
    DependencyProvider.get<CrashReportingService>().recordError(error, stackTrace, fatal: true);
  }
  // On a failed preferences initialization, splash retains its existing retry path.
  (appRunner ?? runApp)(const LocalizationsWrapper(child: App()));
}
