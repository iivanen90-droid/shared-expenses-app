import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:splash_feature/src/data/repository/startup_repository_impl.dart';
import 'package:splash_feature/src/data/source/startup_source.dart';

class _Source extends Mock implements StartupSource {}

class _Initializer extends Mock implements ApplicationInitializer {}

class _CrashReporting extends Mock implements CrashReportingService {}

void main() {
  test('readiness is required to continue', () async {
    final status = StartupStatusImpl();
    final initializer = _Initializer();
    when(initializer.initialize).thenAnswer((_) async {});
    final repository = StartupRepositoryImpl(
      source: StartupSourceImpl(startupStatus: status, initializer: initializer),
      crashReporting: _CrashReporting(),
    );
    expect((await repository.checkReadiness()).isLeft(), isTrue);
    status.markReady();
    expect((await repository.checkReadiness()).isRight(), isTrue);
  });
  test('source exceptions are mapped to Failure', () async {
    final source = _Source();
    final reporting = _CrashReporting();
    final error = StateError('storage is unavailable');
    when(source.isReady).thenThrow(error);
    final repository = StartupRepositoryImpl(source: source, crashReporting: reporting);
    expect((await repository.checkReadiness()).isLeft(), isTrue);
    verify(() => reporting.report(error: error)).called(1);
  });
}
