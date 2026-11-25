import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:core/src/database/supabase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late SupabaseDatabase database;
  late List<http.Request> requests;
  late http.Response response;
  Object? transportFailure;
  setUp(() async {
    requests = [];
    transportFailure = null;
    response = http.Response('[{"id":"row-1"}]', 200, headers: {'content-type': 'application/json'});
    client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final failure = transportFailure;
        if (failure != null) throw failure;
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'sub': '10000000-0000-4000-8000-000000000001',
              'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            }),
          ),
        )
        .replaceAll('=', '');
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.dGVzdA',
        'refresh_token': 'test-only',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
        'user': {
          'id': '10000000-0000-4000-8000-000000000001',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
    database = SupabaseDatabase(client: () => client);
  });
  tearDown(() => client.dispose());

  test('uses the supplied initialized session for bounded filtered reads', () async {
    final rows = await database.read(table: 'records', equals: {'id': 'row-1'}, offset: 10, limit: 20);
    expect(rows.getOrElse((_) => []), [
      {'id': 'row-1'},
    ]);
    expect(database.currentUserId, '10000000-0000-4000-8000-000000000001');
    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url.path, '/rest/v1/records');
    expect(request.url.queryParameters['id'], 'eq.row-1');
    expect(request.url.queryParameters['offset'], '10');
    expect(request.url.queryParameters['limit'], '20');
    expect(request.headers['authorization'], startsWith('Bearer ey'));
  });

  test('supports insert, filtered update and filtered delete without exposing the SDK', () async {
    expect((await database.insert(table: 'records', values: {'name': 'Test'})).isRight(), isTrue);
    expect(requests.last.method, 'POST');
    expect(jsonDecode(requests.last.body), {'name': 'Test'});
    expect(
      (await database.update(table: 'records', values: {'name': 'Changed'}, equals: {'id': 'row-1'})).isRight(),
      isTrue,
    );
    expect(requests.last.method, 'PATCH');
    expect(requests.last.url.queryParameters['id'], 'eq.row-1');
    expect((await database.delete(table: 'records', equals: {'id': 'row-1'})).isRight(), isTrue);
    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.queryParameters['id'], 'eq.row-1');
    expect(requests, hasLength(3));
  });

  test('calls a transaction RPC with exactly the provided parameters', () async {
    response = http.Response('"stable-id"', 200, headers: {'content-type': 'application/json'});
    final result = await database.call(function: 'create_record', parameters: {'p_id': 'stable-id'});
    expect(result.getOrElse((_) => null), 'stable-id');
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/rest/v1/rpc/create_record');
    expect(jsonDecode(requests.single.body), {'p_id': 'stable-id'});
  });

  test('rejects unfiltered mutations and invalid pagination before sending requests', () async {
    expect((await database.update(table: 'records', values: {'name': 'x'}, equals: {})).isLeft(), isTrue);
    expect((await database.delete(table: 'records', equals: {})).isLeft(), isTrue);
    expect((await database.read(table: 'records', offset: -1)).isLeft(), isTrue);
    expect((await database.read(table: 'records', limit: 1001)).isLeft(), isTrue);
    expect(requests, isEmpty);
  });

  test('missing configuration or session never issues a data request', () async {
    final absent = SupabaseDatabase(client: () => null);
    expect((await absent.read(table: 'records')).getOrElse((_) => []), isEmpty);
    expect(
      (await absent.read(table: 'records')).swap().getOrElse((_) => throw StateError('failure')).kind,
      DatabaseFailureKind.configuration,
    );
    await client.auth.signOut(scope: SignOutScope.local);
    requests.clear();
    expect(
      (await database.read(table: 'records')).swap().getOrElse((_) => throw StateError('failure')).kind,
      DatabaseFailureKind.authentication,
    );
    expect(requests, isEmpty);
  });

  for (final error in <Object>[
    const SocketException('test connection lost'),
    TimeoutException('test acknowledgement lost'),
  ]) {
    test('transport failure ${error.runtimeType} is safe and never retries a write', () async {
      transportFailure = error;
      final result = await database.call(function: 'create_record', parameters: {'p_id': 'stable-id'});
      final failure = result.swap().getOrElse((_) => throw StateError('Expected failure'));
      expect(failure.kind, DatabaseFailureKind.connection);
      expect(requests, hasLength(1));
    });
  }

  test('server rejection returns a safe failure without echoing private messages or retrying a write', () async {
    response = http.Response(
      jsonEncode({
        'code': '42501',
        'message': 'private participant name and token',
        'details': 'private database values',
        'hint': 'private URL',
      }),
      403,
      headers: {'content-type': 'application/json'},
    );
    final failure = (await database.insert(
      table: 'records',
      values: {'name': 'Test'},
    )).swap().getOrElse((_) => throw StateError('failure'));
    expect(failure.kind, DatabaseFailureKind.permission);
    expect(failure.toString(), isNot(contains('private')));
    expect(requests, hasLength(1));
  });
}
