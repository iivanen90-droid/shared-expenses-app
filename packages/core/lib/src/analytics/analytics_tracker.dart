import 'dart:convert';

import 'package:core/src/logging/developer_log.dart';

abstract interface class AnalyticsTracker {
  void track({required String eventName, Map<String, Object?> properties = const {}});
  void onBackClick();
}

abstract interface class AnalyticsTrackerFactory {
  AnalyticsTracker create({required String screenName});
}

final class AnalyticsTrackerFactoryImpl implements AnalyticsTrackerFactory {
  const AnalyticsTrackerFactoryImpl({required this._enabled, this._log = writeDeveloperLog});
  final bool _enabled;
  final DeveloperLogWriter _log;

  @override
  AnalyticsTracker create({required String screenName}) =>
      AnalyticsTrackerImpl(screenName: screenName, enabled: _enabled, log: _log);
}

final class AnalyticsTrackerImpl implements AnalyticsTracker {
  AnalyticsTrackerImpl({required this._screenName, required this._enabled, this._log = writeDeveloperLog}) {
    _validateIdentifier(_screenName);
  }
  final String _screenName;
  final bool _enabled;
  final DeveloperLogWriter _log;
  static final _identifier = RegExp(r'^[a-z0-9_]+$');

  static void _validateIdentifier(String value) {
    if (!_identifier.hasMatch(value)) throw ArgumentError('Analytics names must be non-empty identifiers.');
  }

  @override
  void track({required String eventName, Map<String, Object?> properties = const {}}) {
    _validateIdentifier(eventName);
    final name = '${eventName}_$_screenName';
    if (name.length > 40) throw ArgumentError('The complete analytics event name must not exceed 40 characters.');
    for (final entry in properties.entries) {
      _validateIdentifier(entry.key);
      final value = entry.value;
      if (!(value == null || value is String || value is bool || (value is num && value.isFinite))) {
        throw ArgumentError('Analytics properties must be finite numbers, strings, booleans or null.');
      }
    }
    if (_enabled) _log(jsonEncode({'event': name, 'properties': properties}), name: 'tricount.analytics');
  }

  @override
  void onBackClick() => track(eventName: 'back_click');
}
