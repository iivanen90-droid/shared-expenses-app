import 'package:home_feature/src/data/model/home_group_record.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';

final class HomeGroupMapper {
  const HomeGroupMapper();

  HomeGroupRecord toRecord(NewGroup group) => HomeGroupRecord(
    name: group.name,
    emoji: group.emoji,
    currencyCode: group.currencyCode,
    participants: group.participants,
  );

  HomeGroup toDomain(HomeGroupRecord record) => HomeGroup(
    id: record.id,
    name: record.name,
    emoji: record.emoji,
    currencyCode: record.currencyCode,
    participants: List<String>.unmodifiable(record.participants),
  );
}
