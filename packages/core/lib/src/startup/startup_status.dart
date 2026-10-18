abstract interface class StartupStatus {
  bool get isReady;
  void markReady();
}

final class StartupStatusImpl implements StartupStatus {
  bool _isReady = false;
  @override
  bool get isReady => _isReady;
  @override
  void markReady() => _isReady = true;
}
