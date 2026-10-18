import 'package:core/core.dart';

final class ApplicationInitializerImpl implements ApplicationInitializer {
  const ApplicationInitializerImpl({required this._startupStatus});
  final StartupStatus _startupStatus;
  @override
  Future<void> initialize() async {
    _startupStatus.markReady();
  }
}
