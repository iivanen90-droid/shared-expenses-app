import 'package:core/src/analytics/crash_reporting_service.dart';
import 'package:core/src/api_client/api_client.dart';
import 'package:core/src/api_client/api_error.dart';
import 'package:core/src/api_client/dio_client_configuration.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class DioClient implements ApiClient {
  DioClient({
    DioClientConfiguration configuration = const DioClientConfiguration(),
    required this._crashReporting,
    List<Interceptor> interceptors = const [],
    HttpClientAdapter? adapter,
  }) : _dio = Dio(_validatedOptions(configuration)) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.addAll(interceptors);
  }

  DioClient._({required this._dio, required this._crashReporting});

  final Dio _dio;
  final CrashReportingService _crashReporting;
  bool _closed = false;

  static BaseOptions _validatedOptions(DioClientConfiguration configuration) {
    final uri = Uri.tryParse(configuration.baseUrl);
    if (configuration.baseUrl.isNotEmpty &&
        (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https'))) {
      throw ArgumentError('baseUrl must be an absolute HTTP(S) URL or empty.');
    }
    for (final timeout in [configuration.connectTimeout, configuration.sendTimeout, configuration.receiveTimeout]) {
      if (timeout <= Duration.zero) throw ArgumentError('Network timeouts must be positive.');
    }
    return BaseOptions(
      baseUrl: configuration.baseUrl,
      connectTimeout: configuration.connectTimeout,
      sendTimeout: configuration.sendTimeout,
      receiveTimeout: configuration.receiveTimeout,
      headers: Map<String, Object?>.of(configuration.headers),
    );
  }

  void addInterceptor(Interceptor interceptor) {
    if (_closed) throw StateError('DioClient is closed.');
    _dio.interceptors.add(interceptor);
  }

  void close({bool force = false}) {
    if (_closed) return;
    _closed = true;
    _dio.close(force: force);
  }

  Future<Either<ApiError, T>> _execute<T>({
    required String method,
    required String path,
    required T Function(Object?) decode,
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
  }) async {
    if (_closed) return const Left(ApiError(kind: ApiErrorKind.closed));
    final uri = Uri.tryParse(path);
    final absoluteHttp = uri != null && uri.hasAuthority && (uri.scheme == 'http' || uri.scheme == 'https');
    if (_dio.options.baseUrl.isEmpty && !absoluteHttp) return const Left(ApiError(kind: ApiErrorKind.configuration));
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: headers),
        cancelToken: cancelToken,
      );
    } on DioException catch (error, stackTrace) {
      final kind = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => ApiErrorKind.timeout,
        DioExceptionType.connectionError => ApiErrorKind.connection,
        DioExceptionType.badCertificate => ApiErrorKind.certificate,
        DioExceptionType.badResponse => ApiErrorKind.http,
        DioExceptionType.cancel => ApiErrorKind.cancelled,
        DioExceptionType.unknown => error.error is FormatException ? ApiErrorKind.decoding : ApiErrorKind.unknown,
      };
      if (kind != ApiErrorKind.cancelled) _report(error, stackTrace);
      return Left(ApiError(kind: kind, statusCode: error.response?.statusCode));
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace);
      return const Left(ApiError());
    }
    try {
      return Right(decode(response.data));
    } on Object catch (error, stackTrace) {
      _report(error, stackTrace);
      return Left(ApiError(kind: ApiErrorKind.decoding, statusCode: response.statusCode));
    }
  }

  void _report(Object error, StackTrace stackTrace) {
    try {
      _crashReporting.recordError(error, stackTrace);
    } on Object {
      // Preserve the typed request result even when a reporter fails.
    }
  }

  @override
  Future<Either<ApiError, T>> get<T>({
    required String path,
    required T Function(Object?) decode,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
  }) => _execute(
    method: 'GET',
    path: path,
    decode: decode,
    queryParameters: queryParameters,
    headers: headers,
    cancelToken: cancelToken,
  );
  @override
  Future<Either<ApiError, T>> post<T>({
    required String path,
    required T Function(Object?) decode,
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
  }) => _execute(
    method: 'POST',
    path: path,
    decode: decode,
    data: data,
    queryParameters: queryParameters,
    headers: headers,
    cancelToken: cancelToken,
  );
  @override
  Future<Either<ApiError, T>> delete<T>({
    required String path,
    required T Function(Object?) decode,
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
  }) => _execute(
    method: 'DELETE',
    path: path,
    decode: decode,
    data: data,
    queryParameters: queryParameters,
    headers: headers,
    cancelToken: cancelToken,
  );
}

/// Compatibility constructor for existing callers that provide an already configured Dio.
/// New code uses DioClient with DioClientConfiguration and an injected reporter.
final class ApiClientImpl extends DioClient {
  ApiClientImpl({required super.dio}) : super._(crashReporting: const CrashReportingServiceImpl());
}
