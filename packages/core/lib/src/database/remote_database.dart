import 'package:core/src/domain/failure/failure.dart';
import 'package:fpdart/fpdart.dart';

typedef DatabaseRow = Map<String, dynamic>;

enum DatabaseFailureKind { configuration, authentication, permission, conflict, connection, invalidData, unknown }

final class DatabaseFailure extends Failure {
  const DatabaseFailure(this.kind);
  final DatabaseFailureKind kind;
}

/// Online access only. Callers own table names, mapping and synchronization policy.
abstract interface class RemoteDatabase {
  String? get currentUserId;
  Future<Either<DatabaseFailure, List<DatabaseRow>>> read({
    required String table,
    Map<String, Object> equals = const {},
    int offset = 0,
    int limit = 100,
  });
  Future<Either<DatabaseFailure, List<DatabaseRow>>> insert({required String table, required DatabaseRow values});
  Future<Either<DatabaseFailure, List<DatabaseRow>>> update({
    required String table,
    required DatabaseRow values,
    required Map<String, Object> equals,
  });
  Future<Either<DatabaseFailure, List<DatabaseRow>>> delete({
    required String table,
    required Map<String, Object> equals,
  });
  Future<Either<DatabaseFailure, Object?>> call({required String function, required DatabaseRow parameters});
}
