import 'package:core/core.dart';

abstract interface class ApplicationInitializer {
  Future<void> initialize();
}

final class ApplicationInitializerImpl implements ApplicationInitializer {
  const ApplicationInitializerImpl({required this._startupStatus});
  final StartupStatus _startupStatus;
  @override
  Future<void> initialize() async {
    _startupStatus.markReady();
  }
}
