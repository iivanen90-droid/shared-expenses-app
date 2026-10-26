import 'package:core/core.dart';

abstract interface class HomeAnalytics {
  void onOpened();
}

enum _HomeEvent { opened }

final class HomeAnalyticsImpl implements HomeAnalytics {
  HomeAnalyticsImpl({required AnalyticsTrackerFactory trackerFactory})
    : _tracker = trackerFactory.create(screenName: _screenName);
  static const _screenName = 'home_page';
  final AnalyticsTracker _tracker;
  @override
  void onOpened() => _tracker.track(eventName: _HomeEvent.opened.name);
}
