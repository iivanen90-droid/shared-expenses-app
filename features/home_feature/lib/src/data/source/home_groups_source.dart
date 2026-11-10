import 'package:core/core.dart';
import 'package:home_feature/objectbox.g.dart';
import 'package:home_feature/src/data/model/home_group_record.dart';

abstract interface class HomeGroupsSource {
  Stream<List<HomeGroupRecord>> watchGroups();
  Future<HomeGroupRecord> insert(HomeGroupRecord group);
}

final class ObjectBoxHomeGroupsSource implements HomeGroupsSource {
  ObjectBoxHomeGroupsSource({required this._openDatabase});

  final Future<ObjectBoxDatabase> Function() _openDatabase;
  Future<ObjectBoxDatabase>? _opening;

  Future<ObjectBoxDatabase> _open() async {
    try {
      return await Future<ObjectBoxDatabase>.sync(_openDatabase);
    } on Object {
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

  Future<void> close() async {
    final pending = _opening;
    if (pending == null) return;
    final database = await pending.then<ObjectBoxDatabase?>((value) => value, onError: (Object _) => null);
    database?.close();
  }
}
