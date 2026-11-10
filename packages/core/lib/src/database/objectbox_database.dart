import 'dart:async';

import 'package:objectbox/objectbox.dart';

/// Owns an ObjectBox store for a schema supplied by the application.
final class ObjectBoxDatabase {
  ObjectBoxDatabase._(this._store);

  final Store _store;

  /// Pass the schema owner's generated opener. It selects the database directory
  /// and prepares the native library when needed.
  static Future<ObjectBoxDatabase> open(FutureOr<Store> Function() openStore) async =>
      ObjectBoxDatabase._(await openStore());

  /// Returns the box for an entity in the opened schema.
  Box<T> box<T>() => _store.box<T>();

  /// Groups synchronous writes into an atomic transaction.
  R write<R>(R Function() action) => _store.runInTransaction(TxMode.write, action);

  /// Closes the owned store. Calling this again has no effect.
  void close() => _store.close();
}
