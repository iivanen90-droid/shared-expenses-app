import 'package:core/core.dart';

abstract interface class StartupSource {
  Future<bool> isReady();
}

final class StartupSourceImpl implements StartupSource {
  const StartupSourceImpl({required this._startupStatus, required this._initializer});
  final StartupStatus _startupStatus;
  final ApplicationInitializer _initializer;
  @override
  Future<bool> isReady() async {
    if (!_startupStatus.isReady) await _initializer.initialize();
    return _startupStatus.isReady;
  }
}
