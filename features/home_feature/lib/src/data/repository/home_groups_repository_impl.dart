import 'package:home_feature/src/data/source/home_groups_source.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';

final class HomeGroupsRepositoryImpl implements HomeGroupsRepository {
  const HomeGroupsRepositoryImpl({required this._source});

  final HomeGroupsSource _source;

  @override
  List<HomeGroup> getGroups() => _source.getGroups();
}
