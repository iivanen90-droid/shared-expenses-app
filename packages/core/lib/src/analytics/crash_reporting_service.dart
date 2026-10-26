import 'package:core/src/logging/developer_log.dart';

abstract interface class CrashReportingService {
  void recordError(Object error, StackTrace stackTrace, {bool fatal = false});
}

final class CrashReportingServiceImpl implements CrashReportingService {
  const CrashReportingServiceImpl({this._log = writeDeveloperLog});
  final DeveloperLogWriter _log;

  @override
  void recordError(Object error, StackTrace stackTrace, {bool fatal = false}) {
    // Arbitrary exception messages can contain credentials or financial data.
    _log('fatal=$fatal', name: 'tricount.errors', error: error.runtimeType.toString(), stackTrace: stackTrace);
  }
}
