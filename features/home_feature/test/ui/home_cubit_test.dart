import 'package:flutter_test/flutter_test.dart';
import 'package:home_feature/src/ui/home/home_analytics.dart';
import 'package:home_feature/src/ui/home/state/home_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _Analytics extends Mock implements HomeAnalytics {}

void main() {
  test('opening home updates its state and emits the screen event', () async {
    final analytics = _Analytics();
    final cubit = HomeCubit(analytics: analytics);
    addTearDown(cubit.close);
    cubit.load();
    expect(cubit.state.status, HomeStatus.loaded);
    verify(analytics.onOpened).called(1);
  });
}
