import 'package:core/core.dart';
import 'package:home_feature/src/data/model/home_group_record.dart';
import 'package:home_feature/src/data/source/home_groups_source.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';

final class HomeGroupsRepositoryImpl implements HomeGroupsRepository {
  const HomeGroupsRepositoryImpl({required this._source});

  final HomeGroupsSource _source;

  @override
  Stream<Either<GroupsStorageFailure, List<HomeGroup>>> watchGroups() async* {
    try {
      await for (final groups in _source.watchGroups()) {
        yield Right(List<HomeGroup>.unmodifiable(groups.map(_toGroup)));
      }
    } on Object {
      yield const Left(GroupsStorageFailure());
    }
  }

  @override
  Future<Either<GroupsStorageFailure, HomeGroup>> create(NewGroup group) async {
    try {
      final record = await _source.insert(
        HomeGroupRecord(
          name: group.name,
          emoji: group.emoji,
          currencyCode: group.currencyCode,
          participants: group.participants,
        ),
      );
      return Right(_toGroup(record));
    } on Object {
      return const Left(GroupsStorageFailure());
    }
  }

  static HomeGroup _toGroup(HomeGroupRecord record) => HomeGroup(
    id: record.id,
    name: record.name,
    emoji: record.emoji,
    currencyCode: record.currencyCode,
    participants: List<String>.unmodifiable(record.participants),
  );
}
