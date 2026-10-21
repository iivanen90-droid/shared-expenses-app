import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:splash_feature/src/domain/index.dart';
import 'package:splash_feature/src/ui/splash/splash_analytics.dart';
import 'package:splash_feature/src/ui/splash/state/splash_cubit.dart';

class _Interactor extends Mock implements StartupInteractor {}

class _Analytics extends Mock implements SplashAnalytics {}

void main() {
  late _Interactor interactor;
  late _Analytics analytics;
  late SplashCubit cubit;
  setUp(() {
    interactor = _Interactor();
    analytics = _Analytics();
    cubit = SplashCubit(interactor: interactor, analytics: analytics);
  });
  tearDown(() async {
    await cubit.close();
  });
  test('startup completion changes loading to loaded', () async {
    when(interactor.prepare).thenAnswer((_) async => const Right(unit));
    await cubit.load();
    expect(cubit.state.status, SplashStatus.loaded);
    verify(analytics.onOpened).called(1);
  });
  test('a failed startup can be retried', () async {
    when(interactor.prepare).thenAnswer((_) async => const Left(StartupFailure()));
    await cubit.load();
    expect(cubit.state.status, SplashStatus.failed);
    when(interactor.prepare).thenAnswer((_) async => const Right(unit));
    await cubit.load();
    expect(cubit.state.status, SplashStatus.loaded);
  });
  test('late startup completion after closing the page is ignored', () async {
    final pending = Completer<Either<Failure, Unit>>();
    when(interactor.prepare).thenAnswer((_) => pending.future);
    final load = cubit.load();
    await cubit.close();
    pending.complete(const Right(unit));
    await expectLater(load, completes);
    expect(cubit.state.status, SplashStatus.loading);
  });
}
