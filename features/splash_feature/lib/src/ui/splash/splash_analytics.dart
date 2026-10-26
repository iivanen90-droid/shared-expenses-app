import 'package:core/core.dart';

abstract interface class SplashAnalytics {
  void onOpened();
}

enum _SplashEvent { opened }

final class SplashAnalyticsImpl implements SplashAnalytics {
  SplashAnalyticsImpl({required AnalyticsTrackerFactory trackerFactory})
    : _tracker = trackerFactory.create(screenName: _screenName);
  static const _screenName = 'splash_page';
  final AnalyticsTracker _tracker;
  @override
  void onOpened() => _tracker.track(eventName: _SplashEvent.opened.name);
}
