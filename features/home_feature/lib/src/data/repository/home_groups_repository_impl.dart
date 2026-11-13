import 'package:core/core.dart';
import 'package:home_feature/src/data/mapper/home_group_mapper.dart';
import 'package:home_feature/src/data/source/home_groups_source.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';

final class HomeGroupsRepositoryImpl implements HomeGroupsRepository {
  const HomeGroupsRepositoryImpl({required this._source, required this._mapper});

  final HomeGroupsSource _source;
  final HomeGroupMapper _mapper;

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
    try {
      final record = await _source.insert(_mapper.toRecord(group));
      return Right(_mapper.toDomain(record));
    } on Object {
      return const Left(GroupsStorageFailure());
    }
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
