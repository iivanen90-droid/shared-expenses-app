import 'package:core/src/analytics/crash_reporting_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recordError logs the safe error type, supplied stack and fatal=false by default', () {
    final log = LogCapture();
    final service = CrashReportingServiceImpl(log: log.write);
    final stack = StackTrace.fromString('source stack');
    service.recordError(StateError('private text'), stack);
    final entry = log.entries.single;
    expect(entry.name, 'tricount.errors');
    expect(entry.message, 'fatal=false');
    expect(entry.error, 'StateError');
    expect(entry.stackTrace, same(stack));
  });

  test('recordError preserves an explicit fatal=true flag', () {
    final log = LogCapture();
    final stack = StackTrace.fromString('fatal stack');
    CrashReportingServiceImpl(log: log.write).recordError(Exception('private text'), stack, fatal: true);
    expect(log.entries.single.message, 'fatal=true');
    expect(log.entries.single.stackTrace, same(stack));
  });

  test('recordError never serializes an arbitrary exception message', () {
    final log = LogCapture();
    CrashReportingServiceImpl(log: log.write).recordError(_SensitiveError(), StackTrace.empty);
    expect(log.entries.single.error, '_SensitiveError');
    expect(log.entries.single.message, isNot(contains('secret')));
  });
}

final class _SensitiveError implements Exception {
  @override
  String toString() => throw StateError('secret must not be read');
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
