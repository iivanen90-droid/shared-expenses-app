import 'package:core/src/api_client/api_client.dart';
import 'package:core/src/api_client/dio_client.dart';
import 'package:core/src/api_client/dio_client_configuration.dart';
import 'package:core/src/analytics/analytics_tracker.dart';
import 'package:core/src/analytics/crash_reporting_service.dart';
import 'package:core/src/constants/environment_type.dart';
import 'package:core/src/di/dependency_provider.dart';
import 'package:core/src/preferences_storage/preferences_storage.dart';
import 'package:core/src/startup/startup_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class CoreDependenciesModuleResolver {
  static void register({
    required EnvironmentType environment,
    DioClientConfiguration dioConfiguration = const DioClientConfiguration(),
  }) {
    DependencyProvider.registerLazySingleton<StartupStatus>(StartupStatusImpl.new);
    DependencyProvider.registerLazySingleton<AnalyticsTrackerFactory>(
      () => AnalyticsTrackerFactoryImpl(enabled: environment.isDebug),
    );
    DependencyProvider.registerFactoryWithParams<AnalyticsTracker, String, void>(
      (screenName, _) => DependencyProvider.get<AnalyticsTrackerFactory>().create(screenName: screenName),
    );
    DependencyProvider.registerFactory<CrashReportingService>(CrashReportingServiceImpl.new);
    DependencyProvider.registerLazySingleton<DioClient>(
      () => DioClient(configuration: dioConfiguration, crashReporting: DependencyProvider.get<CrashReportingService>()),
      dispose: (client) => client.close(force: true),
    );
    DependencyProvider.registerLazySingleton<ApiClient>(() => DependencyProvider.get<DioClient>());
    DependencyProvider.registerLazySingleton<PreferencesStorage>(
      () => PreferencesStorageImpl(preferences: SharedPreferencesAsync()),
    );
  }
}
