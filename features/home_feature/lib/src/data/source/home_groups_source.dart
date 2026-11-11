import 'package:home_feature/src/domain/entity/home_group.dart';

abstract interface class HomeGroupsSource {
  List<HomeGroup> getGroups();
}

final class DemoHomeGroupsSource implements HomeGroupsSource {
  const DemoHomeGroupsSource();

  @override
  List<HomeGroup> getGroups() => const [
    HomeGroup(name: 'Barcelona', emoji: '🏖️'),
    HomeGroup(name: 'Kyiv', emoji: '☕'),
    HomeGroup(name: 'Carpathians', emoji: '🏔️'),
  ];
}
