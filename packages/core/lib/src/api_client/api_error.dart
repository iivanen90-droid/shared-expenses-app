import 'package:core/src/domain/failure/failure.dart';

enum ApiErrorKind { configuration, connection, timeout, certificate, http, cancelled, decoding, closed, unknown }

/// Transport metadata only: never retains response bodies, URLs, headers or exception messages.
final class ApiError extends Failure {
  const ApiError({this.kind = ApiErrorKind.unknown, this.statusCode});
  final ApiErrorKind kind;
  final int? statusCode;
}
