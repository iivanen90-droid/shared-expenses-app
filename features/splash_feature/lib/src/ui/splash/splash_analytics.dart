import 'package:core/core.dart';

abstract interface class SplashAnalytics {
  void onOpened();
}

final class SplashAnalyticsImpl implements SplashAnalytics {
  const SplashAnalyticsImpl({required this._tracker});
  static const _screenName = 'splash_page';
  final AnalyticsTracker _tracker;
  @override
  void onOpened() => _tracker.track(event: 'opened_$_screenName');
}
