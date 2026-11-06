import 'package:core/src/api_client/api_error.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ApiClient {
  Future<Either<ApiError, T>> get<T>({
    required String path,
    required T Function(Object?) decode,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
  });
  Future<Either<ApiError, T>> post<T>({
    required String path,
    required T Function(Object?) decode,
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
  });
  Future<Either<ApiError, T>> delete<T>({
    required String path,
    required T Function(Object?) decode,
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
  });
}
