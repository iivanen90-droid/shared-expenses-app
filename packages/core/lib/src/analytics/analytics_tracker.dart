import 'dart:developer' as developer;

abstract interface class AnalyticsTracker {
  void track({required String event});
}

final class AnalyticsTrackerImpl implements AnalyticsTracker {
  const AnalyticsTrackerImpl({required this._enabled});
  final bool _enabled;
  @override
  void track({required String event}) {
    if (!RegExp(r'^[a-z0-9_]{1,40}$').hasMatch(event)) {
      throw ArgumentError('Analytics events must be identifiers up to 40 characters.');
    }
    if (_enabled) developer.log(event, name: 'tricount.analytics');
  }
}

abstract interface class CrashReportingService {
  void report({required Object error});
}

final class CrashReportingServiceImpl implements CrashReportingService {
  const CrashReportingServiceImpl();
  @override
  void report({required Object error}) {
    // Exception messages may contain URLs, credentials, or financial data.
    developer.log(error.runtimeType.toString(), name: 'tricount.errors');
  }
}
