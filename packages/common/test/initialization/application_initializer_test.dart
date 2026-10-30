import 'dart:ui';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FlutterExceptionHandler? originalFlutter;
  ErrorCallback? originalPlatform;
  ApplicationInitializerImpl? initializer;
  late StartupStatus status;
  late _Reporter reporter;

  setUp(() {
    originalFlutter = FlutterError.onError;
    originalPlatform = PlatformDispatcher.instance.onError;
    FlutterError.onError = null;
    PlatformDispatcher.instance.onError = null;
    status = StartupStatusImpl();
    reporter = _Reporter();
    initializer = null;
  });
  tearDown(() async {
    await DependencyProvider.reset();
    initializer?.dispose();
    FlutterError.onError = originalFlutter;
    PlatformDispatcher.instance.onError = originalPlatform;
  });

  test('repeated initialization marks ready without duplicating error reports', () async {
    final current = ApplicationInitializerImpl(startupStatus: status, crashReporting: reporter);
    initializer = current;
    await Future.wait([current.initialize(), current.initialize()]);
    await current.initialize();
    expect(status.isReady, isTrue);
    FlutterError.onError?.call(FlutterErrorDetails(exception: StateError('Failure')));
    expect(reporter.errors, hasLength(1));
  });

  test('Flutter errors preserve the original error and stack and chain the previous handler', () async {
    var forwarded = false;
    FlutterError.onError = (_) => forwarded = true;
    final current = ApplicationInitializerImpl(startupStatus: status, crashReporting: reporter);
    initializer = current;
    await current.initialize();
    final error = StateError('Framework error');
    final stack = StackTrace.fromString('original framework stack');
    FlutterError.onError?.call(FlutterErrorDetails(exception: error, stack: stack));
    expect(reporter.errors.single.error, same(error));
    expect(reporter.errors.single.stack, same(stack));
    expect(reporter.errors.single.fatal, isFalse);
    expect(forwarded, isTrue);
  });

  test('unhandled root-isolate errors are reported as fatal and marked handled', () async {
    final current = ApplicationInitializerImpl(startupStatus: status, crashReporting: reporter);
    initializer = current;
    await current.initialize();
    final error = StateError('Async error');
    final stack = StackTrace.fromString('original async stack');
    expect(PlatformDispatcher.instance.onError?.call(error, stack), isTrue);
    expect(reporter.errors.single.error, same(error));
    expect(reporter.errors.single.stack, same(stack));
    expect(reporter.errors.single.fatal, isTrue);
  });

  test('a previous platform handler retains its return value', () async {
    var forwarded = false;
    PlatformDispatcher.instance.onError = (_, _) {
      forwarded = true;
      return false;
    };
    final current = ApplicationInitializerImpl(startupStatus: status, crashReporting: reporter);
    initializer = current;
    await current.initialize();
    expect(PlatformDispatcher.instance.onError?.call(StateError('Error'), StackTrace.empty), isFalse);
    expect(forwarded, isTrue);
    expect(reporter.errors, hasLength(1));
  });

  test('reporter failures do not recursively throw from the platform handler', () async {
    reporter.fail = true;
    final current = ApplicationInitializerImpl(startupStatus: status, crashReporting: reporter);
    initializer = current;
    await current.initialize();
    expect(PlatformDispatcher.instance.onError?.call(StateError('Error'), StackTrace.empty), isFalse);
  });

  test('DI uses one initializer and reset restores the previous global handlers', () async {
    void previousFlutter(FlutterErrorDetails details) {}
    bool previousPlatform(Object error, StackTrace stack) => false;
    FlutterError.onError = previousFlutter;
    PlatformDispatcher.instance.onError = previousPlatform;
    MainDependenciesModuleResolver.register(environment: EnvironmentType.dev);
    expect(DependencyProvider.get<ApplicationInitializer>(), same(DependencyProvider.get<ApplicationInitializer>()));
    expect(DependencyProvider.isRegistered<PreferencesStorage>(), isTrue);
    await DependencyProvider.get<ApplicationInitializer>().initialize();
    await DependencyProvider.reset();
    expect(FlutterError.onError, same(previousFlutter));
    expect(PlatformDispatcher.instance.onError, same(previousPlatform));
  });

  test('cleanup does not overwrite a handler installed later by another owner', () async {
    final current = ApplicationInitializerImpl(startupStatus: status, crashReporting: reporter);
    initializer = current;
    await current.initialize();
    void laterFlutter(FlutterErrorDetails details) {}
    bool laterPlatform(Object error, StackTrace stack) => true;
    FlutterError.onError = laterFlutter;
    PlatformDispatcher.instance.onError = laterPlatform;
    current.dispose();
    expect(FlutterError.onError, same(laterFlutter));
    expect(PlatformDispatcher.instance.onError, same(laterPlatform));
  });
}

final class _RecordedError {
  const _RecordedError(this.error, this.stack, this.fatal);
  final Object error;
  final StackTrace stack;
  final bool fatal;
}

final class _Reporter implements CrashReportingService {
  final errors = <_RecordedError>[];
  bool fail = false;
  @override
  void recordError(Object error, StackTrace stackTrace, {bool fatal = false}) {
    if (fail) throw StateError('Reporter failed');
    errors.add(_RecordedError(error, stackTrace, fatal));
  }
}
