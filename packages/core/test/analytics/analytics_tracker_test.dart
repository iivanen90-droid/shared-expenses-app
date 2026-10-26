import 'dart:convert';

import 'package:core/core.dart';
import 'package:core/src/analytics/analytics_tracker.dart' show AnalyticsTrackerFactoryImpl;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LogCapture log;
  late AnalyticsTrackerFactory factory;
  setUp(() {
    log = LogCapture();
    factory = AnalyticsTrackerFactoryImpl(enabled: true, log: log.write);
  });
  tearDown(DependencyProvider.reset);

  test('track logs the scoped name and technical properties together', () {
    final tracker = factory.create(screenName: 'home_page');
    tracker.track(
      eventName: 'opened',
      properties: {'source': 'startup', 'attempt': 1, 'retry': false, 'optional': null},
    );
    expect(log.entries.single.name, 'tricount.analytics');
    expect(jsonDecode(log.entries.single.message), {
      'event': 'opened_home_page',
      'properties': {'source': 'startup', 'attempt': 1, 'retry': false, 'optional': null},
    });
  });

  test('trackers from the same factory retain their own screen names', () {
    final home = factory.create(screenName: 'home_page');
    final splash = factory.create(screenName: 'splash_page');
    home.track(eventName: 'opened');
    splash.track(eventName: 'opened');
    expect(log.entries.map((entry) => (jsonDecode(entry.message) as Map<String, dynamic>)['event']), [
      'opened_home_page',
      'opened_splash_page',
    ]);
  });

  test('the full event name may contain exactly 40 characters', () {
    final event = List.filled(35, 'a').join();
    factory.create(screenName: 'page').track(eventName: event);
    final data = jsonDecode(log.entries.single.message) as Map<String, dynamic>;
    expect(data['event'], '${event}_page');
    expect((data['event'] as String).length, 40);
  });

  test('a 41-character name is rejected before logging and is never truncated', () {
    final event = List.filled(36, 'a').join();
    expect(() => factory.create(screenName: 'page').track(eventName: event), throwsArgumentError);
    expect(log.entries, isEmpty);
  });

  for (final name in ['', 'event name', 'event?']) {
    test('invalid event identifier "$name" is rejected', () {
      expect(() => factory.create(screenName: 'page').track(eventName: name), throwsArgumentError);
      expect(log.entries, isEmpty);
    });
  }
  for (final name in ['', 'screen name']) {
    test('invalid screen identifier "$name" is rejected by the factory', () {
      expect(() => factory.create(screenName: name), throwsArgumentError);
      expect(log.entries, isEmpty);
    });
  }

  test('onBackClick uses the same suffix and supplies empty properties', () {
    factory.create(screenName: 'home_page').onBackClick();
    expect(jsonDecode(log.entries.single.message), {'event': 'back_click_home_page', 'properties': {}});
  });

  test('onBackClick accepts 40 characters and rejects 41 without logging', () {
    final valid = List.filled(29, 's').join();
    factory.create(screenName: valid).onBackClick();
    final data = jsonDecode(log.entries.single.message) as Map<String, dynamic>;
    expect((data['event'] as String).length, 40);
    log.entries.clear();
    expect(() => factory.create(screenName: '${valid}s').onBackClick(), throwsArgumentError);
    expect(log.entries, isEmpty);
  });

  test('arbitrary objects cannot be serialized into analytics properties', () {
    expect(
      () => factory.create(screenName: 'page').track(eventName: 'opened', properties: {'value': Object()}),
      throwsArgumentError,
    );
    expect(log.entries, isEmpty);
  });

  test('non-finite numeric properties are rejected before logging', () {
    expect(
      () => factory.create(screenName: 'page').track(eventName: 'opened', properties: {'value': double.nan}),
      throwsArgumentError,
    );
    expect(log.entries, isEmpty);
  });

  test('property keys must be identifiers', () {
    expect(
      () => factory.create(screenName: 'page').track(eventName: 'opened', properties: {'bad key': true}),
      throwsArgumentError,
    );
    expect(log.entries, isEmpty);
  });

  test('disabled analytics emits no local records', () {
    final disabled = AnalyticsTrackerFactoryImpl(enabled: false, log: log.write).create(screenName: 'page');
    disabled.track(eventName: 'opened', properties: {'source': 'startup'});
    disabled.onBackClick();
    expect(log.entries, isEmpty);
  });

  test('disabled analytics still rejects overlong names', () {
    final disabled = AnalyticsTrackerFactoryImpl(enabled: false, log: log.write).create(screenName: 'page');
    expect(() => disabled.track(eventName: List.filled(36, 'a').join()), throwsArgumentError);
    expect(log.entries, isEmpty);
  });

  test('core DI exposes the factory, parameterized tracker and crash service', () {
    CoreDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    final factory = DependencyProvider.get<AnalyticsTrackerFactory>();
    final first = factory.create(screenName: 'home_page');
    final second = DependencyProvider.getWithParams<AnalyticsTracker>(param1: 'splash_page');
    expect(first, isA<AnalyticsTracker>());
    expect(second, isNot(same(first)));
    first.track(eventName: 'opened');
    second.onBackClick();
    expect(DependencyProvider.get<CrashReportingService>(), isA<CrashReportingService>());
  });
}

final class LogEntry {
  const LogEntry({required this.message, required this.name, this.error, this.stackTrace});
  final String message;
  final String name;
  final Object? error;
  final StackTrace? stackTrace;
}

final class LogCapture {
  final entries = <LogEntry>[];
  void write(String message, {required String name, Object? error, StackTrace? stackTrace}) {
    entries.add(LogEntry(message: message, name: name, error: error, stackTrace: stackTrace));
  }
}
