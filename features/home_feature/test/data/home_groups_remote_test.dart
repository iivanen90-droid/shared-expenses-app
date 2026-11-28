import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_feature/src/data/mapper/home_group_mapper.dart';
import 'package:home_feature/src/data/model/home_group_record.dart';
import 'package:home_feature/src/data/repository/home_groups_repository_impl.dart';
import 'package:home_feature/src/data/source/home_groups_remote_source.dart';
import 'package:home_feature/src/data/source/home_groups_source.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:mocktail/mocktail.dart';

class _Database extends Mock implements RemoteDatabase {}

void main() {
  const draft = (name: 'Trip', emoji: '🌍', currencyCode: 'UAH', participants: ['Alex', 'Sam']);
  late _Local local;
  late _Database database;
  late HomeGroupsRemoteSource remote;
  late HomeGroupsRepositoryImpl repository;
  setUp(() {
    local = _Local();
    database = _Database();
    when(() => database.currentUserId).thenReturn('owner-a');
    remote = HomeGroupsRemoteSourceImpl(database: database);
    repository = HomeGroupsRepositoryImpl(source: local, mapper: const HomeGroupMapper(), remote: remote);
  });

  test('anonymous creation stays local and is never claimed on later sign-in', () async {
    when(() => database.currentUserId).thenReturn(null);
    final saved = (await repository.create(draft)).getOrElse((_) => throw StateError('save'));
    expect(saved.remoteState, GroupRemoteState.localOnly);
    expect(saved.stableId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    when(() => database.currentUserId).thenReturn('owner-a');
    await repository.watchGroups().first;
    expect(local.records.single.ownerId, isEmpty);
    verifyNever(
      () => database.call(
        function: any(named: 'function'),
        parameters: any(named: 'parameters'),
      ),
    );
  });

  test('local group exists before atomic upload and identical replay uses the same UUID', () async {
    final payloads = <DatabaseRow>[];
    when(
      () => database.call(
        function: any(named: 'function'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((call) async {
      final values = call.namedArguments[#parameters] as DatabaseRow;
      payloads.add(values);
      expect(local.records, hasLength(1));
      expect(local.records.single.stableId, values['p_id']);
      expect(local.records.single.ownerId, values['p_owner_id']);
      return Right(values['p_id']);
    });
    final saved = (await repository.create(draft)).getOrElse((_) => throw StateError('save'));
    expect(saved.remoteState, GroupRemoteState.uploaded);
    expect(local.records.single.remoteState, 'uploaded');
    await remote.create(local.records.single);
    expect(payloads, hasLength(2));
    expect(payloads[0], payloads[1]);
  });

  test('remote failure keeps one local group and persists unconfirmed status', () async {
    when(
      () => database.call(
        function: any(named: 'function'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async => const Left(DatabaseFailure(DatabaseFailureKind.connection)));
    final saved = (await repository.create(draft)).getOrElse((_) => throw StateError('save'));
    expect(saved.remoteState, GroupRemoteState.notConfirmed);
    expect(local.records.single.participants, draft.participants);
    final reread = (await repository.getGroupById(saved.id)).getOrElse((_) => null);
    expect(reread?.stableId, saved.stableId);
    expect(reread?.remoteState, GroupRemoteState.notConfirmed);
  });

  test('failed local save performs no server write', () async {
    local.failInsert = true;
    expect((await repository.create(draft)).isLeft(), isTrue);
    verifyNever(
      () => database.call(
        function: any(named: 'function'),
        parameters: any(named: 'parameters'),
      ),
    );
  });

  test('account switch during local save cannot upload under the new user', () async {
    local.afterInsert = () => when(() => database.currentUserId).thenReturn('owner-b');
    final saved = (await repository.create(draft)).getOrElse((_) => throw StateError('save'));
    expect(saved.remoteState, GroupRemoteState.notConfirmed);
    expect(local.records.single.ownerId, 'owner-a');
    verifyNever(
      () => database.call(
        function: any(named: 'function'),
        parameters: any(named: 'parameters'),
      ),
    );
  });

  test('metadata write failure reports saved local group without encouraging duplicate creation', () async {
    local.failUpdate = true;
    when(
      () => database.call(
        function: any(named: 'function'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((call) async => Right((call.namedArguments[#parameters] as DatabaseRow)['p_id']));
    final saved = (await repository.create(draft)).getOrElse((_) => throw StateError('save'));
    expect(saved.remoteState, GroupRemoteState.notConfirmed);
    expect(local.records, hasLength(1));
    expect(local.records.single.remoteState, 'pending');
  });

  test('unexpected server response never marks a group uploaded', () async {
    when(
      () => database.call(
        function: any(named: 'function'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async => const Right('different-id'));
    final saved = (await repository.create(draft)).getOrElse((_) => throw StateError('save'));
    expect(saved.remoteState, GroupRemoteState.notConfirmed);
  });
}

class _Local implements HomeGroupsSource {
  final records = <HomeGroupRecord>[];
  bool failInsert = false;
  bool failUpdate = false;
  void Function()? afterInsert;
  HomeGroupRecord _copy(HomeGroupRecord group) => HomeGroupRecord(
    id: group.id,
    name: group.name,
    emoji: group.emoji,
    currencyCode: group.currencyCode,
    participants: List.of(group.participants),
    stableId: group.stableId,
    ownerId: group.ownerId,
    remoteState: group.remoteState,
  );
  @override
  Future<HomeGroupRecord> insert(HomeGroupRecord group) async {
    if (failInsert) throw StateError('Local write failed');
    group.id = records.length + 1;
    records.add(_copy(group));
    afterInsert?.call();
    return group;
  }

  @override
  Future<void> updateRemoteState(HomeGroupRecord group) async {
    if (failUpdate) throw StateError('Metadata write failed');
    records[records.indexWhere((record) => record.id == group.id)] = _copy(group);
  }

  @override
  Future<HomeGroupRecord?> getGroupById(int id) async => records.where((group) => group.id == id).firstOrNull;
  @override
  Stream<List<HomeGroupRecord>> watchGroups() => Stream.value(records.map(_copy).toList());
}
