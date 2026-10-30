final class DioClientConfiguration {
  const DioClientConfiguration({
    this.baseUrl = '',
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.headers = const {},
  });

  /// Empty until a backend is configured; relative requests then return a configuration failure.
  final String baseUrl;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;
  final Map<String, Object?> headers;
}
