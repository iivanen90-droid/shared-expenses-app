import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

final class ApiError {
  const ApiError({this.statusCode});
  final int? statusCode;
}

abstract interface class ApiClient {
  Future<Either<ApiError, T>> get<T>({required String path, required T Function(Object?) decode});
}

final class ApiClientImpl implements ApiClient {
  ApiClientImpl({required this._dio});
  final Dio _dio;
  @override
  Future<Either<ApiError, T>> get<T>({required String path, required T Function(Object?) decode}) async {
    try {
      final response = await _dio.get<Object?>(path);
      return Right(decode(response.data));
    } on DioException catch (error) {
      return Left(ApiError(statusCode: error.response?.statusCode));
    } on Object {
      return const Left(ApiError());
    }
  }
}
