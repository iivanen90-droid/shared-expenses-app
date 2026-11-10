import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';

abstract interface class HomeGroupsInteractor {
  List<HomeGroup> getGroups();
}

final class HomeGroupsInteractorImpl implements HomeGroupsInteractor {
  const HomeGroupsInteractorImpl({required this._repository});

  final HomeGroupsRepository _repository;

  @override
  List<HomeGroup> getGroups() => _repository.getGroups();
}
