import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tricount/app.dart';

Future<void> run({required EnvironmentType environment}) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) binding.ensureSemantics();
  await EasyLocalization.ensureInitialized();
  MainDependenciesModuleResolver.register(environment: environment);
  await DependencyProvider.get<ApplicationInitializer>().initialize();
  runApp(const LocalizationsWrapper(child: App()));
}
