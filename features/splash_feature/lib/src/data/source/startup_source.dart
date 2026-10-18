import 'package:core/core.dart';

abstract interface class StartupSource {
  Future<bool> isReady();
}

final class StartupSourceImpl implements StartupSource {
  const StartupSourceImpl({required this._startupStatus});
  final StartupStatus _startupStatus;
  @override
  Future<bool> isReady() async => _startupStatus.isReady;
}
