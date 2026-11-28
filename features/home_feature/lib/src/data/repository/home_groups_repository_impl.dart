import 'package:core/core.dart';
import 'package:home_feature/src/data/mapper/home_group_mapper.dart';
import 'package:home_feature/src/data/model/home_group_record.dart';
import 'package:home_feature/src/data/source/home_groups_source.dart';
import 'package:home_feature/src/data/source/home_groups_remote_source.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';

final class HomeGroupsRepositoryImpl implements HomeGroupsRepository {
  const HomeGroupsRepositoryImpl({required this._source, required this._mapper, this._remote});

  final HomeGroupsSource _source;
  final HomeGroupMapper _mapper;
  final HomeGroupsRemoteSource? _remote;

  @override
  Stream<Either<GroupsStorageFailure, List<HomeGroup>>> watchGroups() async* {
    try {
      await for (final groups in _source.watchGroups()) {
        yield Right(List<HomeGroup>.unmodifiable(groups.map(_mapper.toDomain)));
      }
    } on Object {
      yield const Left(GroupsStorageFailure());
    }
  }

  @override
  Future<Either<GroupsStorageFailure, HomeGroup>> create(NewGroup group) async {
    final HomeGroupRecord record;
    try {
      record = _mapper.toRecord(group);
      final owner = _remote?.currentUserId;
      if (owner != null) {
        record.ownerId = owner;
        record.remoteState = GroupRemoteState.pending.name;
      }
      await _source.insert(record);
    } on Object {
      return const Left(GroupsStorageFailure());
    }
    final remoteSource = _remote;
    if (record.ownerId.isNotEmpty && remoteSource != null) {
      try {
        final result = await remoteSource.create(record);
        record.remoteState = result.isRight() ? GroupRemoteState.uploaded.name : GroupRemoteState.notConfirmed.name;
        await _source.updateRemoteState(record);
      } on Object {
        // A remote/metadata failure must never turn an existing local save into a
        // failed creation: resubmitting the form would create another local group.
        record.remoteState = GroupRemoteState.notConfirmed.name;
      }
    }
    return Right(_mapper.toDomain(record));
  }

  @override
  Future<Either<GroupsStorageFailure, HomeGroup?>> getGroupById(int id) async {
    try {
      final record = await _source.getGroupById(id);
      return Right(record == null ? null : _mapper.toDomain(record));
    } on Object {
      return const Left(GroupsStorageFailure());
    }
  }
}
