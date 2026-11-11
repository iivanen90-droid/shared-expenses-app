import 'package:home_feature/src/domain/entity/home_group.dart';

abstract interface class HomeGroupsRepository {
  List<HomeGroup> getGroups();
}
