import 'dart:async';
import 'dart:io';

import 'package:core/src/database/remote_database.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseDatabase implements RemoteDatabase {
  SupabaseDatabase({required this._client});
  final SupabaseClient? Function() _client;

  @override
  String? get currentUserId => _client()?.auth.currentSession?.user.id;

  Future<Either<DatabaseFailure, T>> _run<T>(Future<T> Function(SupabaseClient) operation) async {
    final client = _client();
    if (client == null) return Left<DatabaseFailure, T>(const DatabaseFailure(DatabaseFailureKind.configuration));
    if (client.auth.currentSession == null) {
      return Left<DatabaseFailure, T>(const DatabaseFailure(DatabaseFailureKind.authentication));
    }
    try {
      return Right(await operation(client).timeout(const Duration(seconds: 15)));
    } on PostgrestException catch (error) {
      final kind = switch (error.code) {
        '42501' => DatabaseFailureKind.permission,
        '23505' => DatabaseFailureKind.conflict,
        'PGRST301' || 'PGRST302' || 'PGRST303' => DatabaseFailureKind.authentication,
        '23502' || '23503' || '23514' || '22023' || '22P02' => DatabaseFailureKind.invalidData,
        _ => DatabaseFailureKind.unknown,
      };
      return Left(DatabaseFailure(kind));
    } on AuthException {
      return Left<DatabaseFailure, T>(const DatabaseFailure(DatabaseFailureKind.authentication));
    } on SocketException {
      return Left<DatabaseFailure, T>(const DatabaseFailure(DatabaseFailureKind.connection));
    } on TimeoutException {
      return Left<DatabaseFailure, T>(const DatabaseFailure(DatabaseFailureKind.connection));
    } on Object {
      // SDK exceptions can contain URLs, tokens or row values; never expose/log them.
      return Left<DatabaseFailure, T>(const DatabaseFailure(DatabaseFailureKind.unknown));
    }
  }

  @override
  Future<Either<DatabaseFailure, List<DatabaseRow>>> read({
    required String table,
    Map<String, Object> equals = const {},
    int offset = 0,
    int limit = 100,
  }) async {
    if (offset < 0 || limit < 1 || limit > 1000) {
      return const Left(DatabaseFailure(DatabaseFailureKind.invalidData));
    }
    return _run((client) async => client.from(table).select().match(equals).range(offset, offset + limit - 1));
  }

  @override
  Future<Either<DatabaseFailure, List<DatabaseRow>>> insert({required String table, required DatabaseRow values}) =>
      _run((client) async => client.from(table).insert(values).select());

  @override
  Future<Either<DatabaseFailure, List<DatabaseRow>>> update({
    required String table,
    required DatabaseRow values,
    required Map<String, Object> equals,
  }) async {
    if (equals.isEmpty || values.isEmpty) return const Left(DatabaseFailure(DatabaseFailureKind.invalidData));
    return _run((client) async => client.from(table).update(values).match(equals).select());
  }

  @override
  Future<Either<DatabaseFailure, List<DatabaseRow>>> delete({
    required String table,
    required Map<String, Object> equals,
  }) async {
    if (equals.isEmpty) return const Left(DatabaseFailure(DatabaseFailureKind.invalidData));
    return _run((client) async => client.from(table).delete().match(equals).select());
  }

  @override
  Future<Either<DatabaseFailure, Object?>> call({required String function, required DatabaseRow parameters}) =>
      _run((client) async => client.rpc(function, params: parameters));
}
