import 'package:core/src/analytics/analytics_tracker.dart';
import 'package:core/src/constants/environment_type.dart';
import 'package:core/src/di/dependency_provider.dart';
import 'package:core/src/preferences_storage/preferences_storage.dart';
import 'package:core/src/startup/startup_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class CoreDependenciesModuleResolver {
  static void register({required EnvironmentType environment}) {
    DependencyProvider.registerLazySingleton<StartupStatus>(StartupStatusImpl.new);
    DependencyProvider.registerFactory<AnalyticsTracker>(() => AnalyticsTrackerImpl(enabled: environment.isDebug));
    DependencyProvider.registerFactory<CrashReportingService>(CrashReportingServiceImpl.new);
    DependencyProvider.registerLazySingleton<PreferencesStorage>(
      () => PreferencesStorageImpl(preferences: SharedPreferencesAsync()),
    );
  }
}
