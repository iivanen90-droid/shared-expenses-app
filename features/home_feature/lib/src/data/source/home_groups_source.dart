import 'dart:async';

import 'package:core/core.dart';
import 'package:home_feature/objectbox.g.dart';
import 'package:home_feature/src/data/model/home_group_record.dart';
import 'package:uuid/uuid.dart';

abstract interface class HomeGroupsSource {
  Stream<List<HomeGroupRecord>> watchGroups();
  Future<HomeGroupRecord> insert(HomeGroupRecord group);
  Future<HomeGroupRecord?> getGroupById(int id);
  Future<void> updateRemoteState(HomeGroupRecord group);
}

final class BoxHomeGroupsSource implements HomeGroupsSource {
  BoxHomeGroupsSource({FutureOr<Store> Function()? storeOpener})
    : _openDatabase = (() => ObjectBoxDatabase.open(storeOpener ?? openStore));

  final Future<ObjectBoxDatabase> Function() _openDatabase;
  Future<ObjectBoxDatabase>? _opening;

  Future<ObjectBoxDatabase> _open() async {
    ObjectBoxDatabase? opened;
    try {
      final database = await _openDatabase();
      opened = database;
      // Add stable identities to existing records without uploading or claiming them.
      final box = database.box<HomeGroupRecord>();
      final missingIdentity = box
          .query(HomeGroupRecord_.stableId.equals('').or(HomeGroupRecord_.stableId.isNull()))
          .build();
      try {
        database.write(() {
          for (final group in missingIdentity.find()) {
            group.stableId = const Uuid().v4();
            if (group.remoteState.isEmpty) group.remoteState = 'localOnly';
            box.put(group, mode: PutMode.update);
          }
        });
      } finally {
        missingIdentity.close();
      }
      return database;
    } on Object {
      opened?.close();
      _opening = null;
      rethrow;
    }
  }

  Future<ObjectBoxDatabase> _database() => _opening ??= _open();

  @override
  Stream<List<HomeGroupRecord>> watchGroups() async* {
    final box = (await _database()).box<HomeGroupRecord>();
    Query<HomeGroupRecord>? activeQuery;
    try {
      await for (final query
          in box.query().order(HomeGroupRecord_.id, flags: Order.descending).watch(triggerImmediately: true)) {
        activeQuery = query;
        yield query.find();
      }
    } finally {
      activeQuery?.close();
    }
  }

  @override
  Future<HomeGroupRecord> insert(HomeGroupRecord group) async {
    final box = (await _database()).box<HomeGroupRecord>();
    group.id = box.put(group, mode: PutMode.insert);
    return group;
  }

  @override
  Future<HomeGroupRecord?> getGroupById(int id) async => (await _database()).box<HomeGroupRecord>().get(id);

  @override
  Future<void> updateRemoteState(HomeGroupRecord group) async {
    (await _database()).box<HomeGroupRecord>().put(group, mode: PutMode.update);
  }

  Future<void> close() async {
    final pending = _opening;
    if (pending == null) return;
    final database = await pending.then<ObjectBoxDatabase?>((value) => value, onError: (Object _) => null);
    database?.close();
  }
}
