import 'package:core/core.dart';

abstract interface class HomeAnalytics {
  void onOpened();
}

final class HomeAnalyticsImpl implements HomeAnalytics {
  const HomeAnalyticsImpl({required this._tracker});
  static const _screenName = 'home_page';
  final AnalyticsTracker _tracker;
  @override
  void onOpened() => _tracker.track(event: 'opened_$_screenName');
}
