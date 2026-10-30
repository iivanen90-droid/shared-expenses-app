import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/src/analytics/crash_reporting_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  int closeCalls = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancelFuture) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) => closeCalls++;
}

final class _Reporting implements CrashReportingService {
  final errors = <Object>[];
  final stacks = <StackTrace>[];
  bool fail = false;
  @override
  void recordError(Object error, StackTrace stackTrace, {bool fatal = false}) {
    if (fail) throw StateError('reporter unavailable');
    errors.add(error);
    stacks.add(stackTrace);
  }
}

ResponseBody _json(String body, {int status = 200}) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  late _Reporting reporting;
  late _Adapter adapter;
  late DioClient client;
  setUp(() {
    reporting = _Reporting();
    adapter = _Adapter((_) async => _json('{"value":7}'));
    client = DioClient(
      configuration: const DioClientConfiguration(baseUrl: 'https://example.invalid/api/'),
      crashReporting: reporting,
      adapter: adapter,
    );
  });
  tearDown(() async {
    client.close(force: true);
    await DependencyProvider.reset();
  });

  test('configuration, query and request headers reach transport without mutating defaults', () async {
    client.close();
    final headers = <String, Object?>{'x-shared': 'original'};
    client = DioClient(
      configuration: DioClientConfiguration(
        baseUrl: 'https://example.invalid/api/',
        connectTimeout: const Duration(seconds: 2),
        sendTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 4),
        headers: headers,
      ),
      crashReporting: reporting,
      adapter: adapter,
    );
    headers['x-shared'] = 'changed outside';
    final result = await client.get<int>(
      path: 'resource',
      queryParameters: {'page': 2},
      headers: {'x-shared': 'override', 'x-request': 'local'},
      decode: (data) => (data as Map<String, dynamic>)['value'] as int,
    );
    expect(result.getOrElse((_) => -1), 7);
    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://example.invalid/api/resource?page=2');
    expect(request.connectTimeout, const Duration(seconds: 2));
    expect(request.sendTimeout, const Duration(seconds: 3));
    expect(request.receiveTimeout, const Duration(seconds: 4));
    expect(request.headers['x-shared'], 'override');
    expect(request.headers['x-request'], 'local');
    await client.get<void>(path: 'resource', decode: (_) {});
    expect(adapter.requests.last.headers['x-shared'], 'original');
    expect(adapter.requests.last.headers.containsKey('x-request'), isFalse);
  });
  for (final method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']) {
    test('$method forwards method, body and query', () async {
      const data = {'sample': true};
      final Future<Either<ApiError, int>> pending = switch (method) {
        'GET' => client.get(path: 'resource', queryParameters: {'p': 1}, decode: (_) => 7),
        'POST' => client.post(path: 'resource', data: data, queryParameters: {'p': 1}, decode: (_) => 7),
        'PUT' => client.put(path: 'resource', data: data, queryParameters: {'p': 1}, decode: (_) => 7),
        'PATCH' => client.patch(path: 'resource', data: data, queryParameters: {'p': 1}, decode: (_) => 7),
        'DELETE' => client.delete(path: 'resource', data: data, queryParameters: {'p': 1}, decode: (_) => 7),
        _ => client.head(path: 'resource', queryParameters: {'p': 1}, decode: (_) => 7),
      };
      expect((await pending).isRight(), isTrue);
      final request = adapter.requests.single;
      expect(request.method, method);
      expect(request.queryParameters['p'], 1);
      expect(request.data, method == 'GET' || method == 'HEAD' ? isNull : data);
    });
  }
  final types = <DioExceptionType, ApiErrorKind>{
    DioExceptionType.connectionTimeout: ApiErrorKind.timeout,
    DioExceptionType.sendTimeout: ApiErrorKind.timeout,
    DioExceptionType.receiveTimeout: ApiErrorKind.timeout,
    DioExceptionType.transformTimeout: ApiErrorKind.timeout,
    DioExceptionType.connectionError: ApiErrorKind.connection,
    DioExceptionType.badCertificate: ApiErrorKind.certificate,
    DioExceptionType.badResponse: ApiErrorKind.http,
    DioExceptionType.cancel: ApiErrorKind.cancelled,
    DioExceptionType.unknown: ApiErrorKind.unknown,
  };
  for (final entry in types.entries) {
    test('${entry.key.name} becomes a Failure and reports the original error', () async {
      DioException? original;
      adapter = _Adapter((options) async {
        original = DioException(
          requestOptions: options,
          type: entry.key,
          response: entry.key == DioExceptionType.badResponse
              ? Response<Object?>(requestOptions: options, statusCode: 503)
              : null,
        );
        throw original!;
      });
      client.close();
      client = DioClient(
        configuration: const DioClientConfiguration(baseUrl: 'https://example.invalid'),
        crashReporting: reporting,
        adapter: adapter,
      );
      final result = await client.get<void>(path: '/resource', decode: (_) {});
      final failure = result.fold((error) => error, (_) => throw StateError('Expected failure'));
      expect(failure, isA<Failure>());
      expect(failure.kind, entry.value);
      if (entry.key == DioExceptionType.badResponse) expect(failure.statusCode, 503);
      if (entry.key == DioExceptionType.cancel) {
        expect(reporting.errors, isEmpty);
      } else {
        expect(reporting.errors.single, same(original));
        expect(reporting.stacks.single.toString(), isNotEmpty);
      }
    });
  }
  test('HTTP responses return status failures without decoding or retrying', () async {
    client.close();
    adapter = _Adapter((_) async => _json('{"private":"body"}', status: 403));
    client = DioClient(
      configuration: const DioClientConfiguration(baseUrl: 'https://example.invalid'),
      crashReporting: reporting,
      adapter: adapter,
    );
    var decoded = false;
    final result = await client.get<void>(
      path: '/resource',
      decode: (_) {
        decoded = true;
      },
    );
    expect(result.fold((error) => error.kind, (_) => null), ApiErrorKind.http);
    expect(result.fold((error) => error.statusCode, (_) => null), 403);
    expect(decoded, isFalse);
    expect(adapter.requests, hasLength(1));
  });
  test('malformed JSON and rejected response shapes return decoding failures', () async {
    client.close();
    adapter = _Adapter((_) async => _json('not json'));
    client = DioClient(
      configuration: const DioClientConfiguration(baseUrl: 'https://example.invalid'),
      crashReporting: reporting,
      adapter: adapter,
    );
    final malformed = await client.get<void>(path: '/resource', decode: (_) {});
    expect(malformed.fold((error) => error.kind, (_) => null), ApiErrorKind.decoding);
    client.close();
    adapter = _Adapter((_) async => _json('{}'));
    client = DioClient(
      configuration: const DioClientConfiguration(baseUrl: 'https://example.invalid'),
      crashReporting: reporting,
      adapter: adapter,
    );
    final decoding = await client.get<void>(path: '/resource', decode: (_) => throw const FormatException());
    expect(decoding.fold((error) => error.kind, (_) => null), ApiErrorKind.decoding);
  });
  test('constructor and added interceptors execute in order', () async {
    client.close();
    final order = <String>[];
    client = DioClient(
      configuration: const DioClientConfiguration(baseUrl: 'https://example.invalid'),
      crashReporting: reporting,
      adapter: adapter,
      interceptors: [
        InterceptorsWrapper(
          onRequest: (options, handler) {
            order.add('constructor');
            options.headers['x-interceptor'] = 'ready';
            handler.next(options);
          },
        ),
      ],
    );
    client.addInterceptor(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          order.add('added');
          handler.next(options);
        },
      ),
    );
    expect((await client.get<void>(path: '/resource', decode: (_) {})).isRight(), isTrue);
    expect(order, ['constructor', 'added']);
    expect(adapter.requests.single.headers['x-interceptor'], 'ready');
  });
  test('pre-cancelled requests return cancellation without traffic or reporting', () async {
    final token = CancelToken()..cancel();
    final result = await client.get<void>(path: '/resource', cancelToken: token, decode: (_) {});
    expect(result.fold((error) => error.kind, (_) => null), ApiErrorKind.cancelled);
    expect(adapter.requests, isEmpty);
    expect(reporting.errors, isEmpty);
  });
  test('an unconfigured backend rejects relative requests locally', () async {
    client.close();
    client = DioClient(configuration: const DioClientConfiguration(), crashReporting: reporting, adapter: adapter);
    final result = await client.get<void>(path: '/resource', decode: (_) {});
    expect(result.fold((error) => error.kind, (_) => null), ApiErrorKind.configuration);
    expect(adapter.requests, isEmpty);
    expect((await client.get<void>(path: 'https://example.invalid/resource', decode: (_) {})).isRight(), isTrue);
  });
  test('invalid configuration fails explicitly before transport', () {
    expect(
      () => DioClient(
        configuration: const DioClientConfiguration(baseUrl: 'relative'),
        crashReporting: reporting,
      ),
      throwsArgumentError,
    );
    expect(
      () => DioClient(
        configuration: const DioClientConfiguration(connectTimeout: Duration.zero),
        crashReporting: reporting,
      ),
      throwsArgumentError,
    );
  });
  test('reporter failure preserves the typed connection failure', () async {
    reporting.fail = true;
    client.addInterceptor(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError));
        },
      ),
    );
    final result = await client.get<void>(path: '/resource', decode: (_) {});
    expect(result.fold((error) => error.kind, (_) => null), ApiErrorKind.connection);
  });
  test('HTTP logging excludes URL, headers, payload and exception message', () async {
    client.close();
    final messages = <String>[];
    client = DioClient(
      configuration: const DioClientConfiguration(
        baseUrl: 'https://example.invalid',
        headers: {'authorization': 'private-header'},
      ),
      crashReporting: CrashReportingServiceImpl(
        log: (message, {required name, error, stackTrace}) {
          messages.add('$name $message $error');
          expect(stackTrace.toString(), isNotEmpty);
        },
      ),
      adapter: _Adapter((_) async => _json('{"secret":"private-body"}', status: 503)),
    );
    final result = await client.post<void>(
      path: '/resource?token=private-query',
      data: {'secret': 'private-request'},
      decode: (_) {},
    );
    expect(result.isLeft(), isTrue);
    expect(messages.single, 'tricount.errors fatal=false DioException');
    for (final secret in ['private-header', 'private-body', 'private-query', 'private-request', 'example.invalid']) {
      expect(messages.single, isNot(contains(secret)));
    }
  });
  test('close is idempotent and later requests return a closed-client failure', () async {
    client.close(force: true);
    client.close(force: true);
    expect(adapter.closeCalls, 1);
    final result = await client.get<void>(path: '/resource', decode: (_) {});
    expect(result.fold((error) => error.kind, (_) => null), ApiErrorKind.closed);
    expect(adapter.requests, isEmpty);
    expect(() => client.addInterceptor(InterceptorsWrapper()), throwsStateError);
  });
  test('DI shares one configured client through both types and closes it on reset', () async {
    CoreDependenciesModuleResolver.register(
      environment: EnvironmentType.dev,
      dioConfiguration: const DioClientConfiguration(baseUrl: 'https://example.invalid/api/'),
    );
    final registered = DependencyProvider.get<DioClient>();
    expect(DependencyProvider.get<DioClient>(), same(registered));
    expect(DependencyProvider.get<ApiClient>(), same(registered));
    registered.addInterceptor(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.uri.toString(), 'https://example.invalid/api/resource');
          handler.resolve(Response<Object?>(requestOptions: options, data: true));
        },
      ),
    );
    expect(
      (await registered.get<bool>(path: 'resource', decode: (data) => data as bool)).getOrElse((_) => false),
      isTrue,
    );
    await DependencyProvider.reset();
    expect(
      (await registered.get<void>(path: 'resource', decode: (_) {})).fold((error) => error.kind, (_) => null),
      ApiErrorKind.closed,
    );
  });
}
