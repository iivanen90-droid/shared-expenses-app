import 'package:core/core.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';

final class GroupsStorageFailure extends Failure {
  const GroupsStorageFailure();
}

abstract interface class HomeGroupsRepository {
  Stream<Either<GroupsStorageFailure, List<HomeGroup>>> watchGroups();
  Future<Either<GroupsStorageFailure, HomeGroup>> create(NewGroup group);
}
