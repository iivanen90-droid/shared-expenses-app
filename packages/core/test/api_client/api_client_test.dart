import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter({required this.status, required this.body});
  final int status;
  final String body;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  test('API responses are decoded into domain-facing values', () async {
    final dio = Dio()..httpClientAdapter = _Adapter(status: 200, body: '{"ready":true}');
    addTearDown(dio.close);
    final client = ApiClientImpl(dio: dio);
    final result = await client.get<bool>(
      path: 'https://example.invalid',
      decode: (data) => switch (data) {
        {'ready': final bool ready} => ready,
        _ => throw const FormatException(),
      },
    );
    expect(result.getOrElse((_) => false), isTrue);
  });
  test('HTTP errors and malformed responses return typed errors', () async {
    final dio = Dio()..httpClientAdapter = _Adapter(status: 503, body: '{}');
    addTearDown(dio.close);
    final client = ApiClientImpl(dio: dio);
    final unavailable = await client.get<bool>(path: 'https://example.invalid', decode: (_) => true);
    expect(unavailable.fold((error) => error.statusCode, (_) => null), 503);
    dio.httpClientAdapter = _Adapter(status: 200, body: '{}');
    final malformed = await client.get<bool>(
      path: 'https://example.invalid',
      decode: (_) => throw const FormatException(),
    );
    expect(malformed.isLeft(), isTrue);
  });
}
