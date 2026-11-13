import 'package:core/core.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';

abstract interface class HomeGroupsInteractor {
  Stream<Either<GroupsStorageFailure, List<HomeGroup>>> watchGroups();
  Future<Either<GroupsStorageFailure, HomeGroup>> create(NewGroup group);
  Future<Either<GroupsStorageFailure, HomeGroup?>> getGroupById(int id);
}

final class HomeGroupsInteractorImpl implements HomeGroupsInteractor {
  const HomeGroupsInteractorImpl({required this._repository});

  final HomeGroupsRepository _repository;

  @override
  Stream<Either<GroupsStorageFailure, List<HomeGroup>>> watchGroups() => _repository.watchGroups();

  @override
  Future<Either<GroupsStorageFailure, HomeGroup>> create(NewGroup group) => _repository.create(group);

  @override
  Future<Either<GroupsStorageFailure, HomeGroup?>> getGroupById(int id) => _repository.getGroupById(id);
}
