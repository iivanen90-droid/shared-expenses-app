import 'package:home_feature/src/data/model/home_group_record.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:uuid/uuid.dart';

final class HomeGroupMapper {
  const HomeGroupMapper();

  HomeGroupRecord toRecord(NewGroup group) => HomeGroupRecord(
    name: group.name,
    emoji: group.emoji,
    currencyCode: group.currencyCode,
    participants: group.participants,
    stableId: const Uuid().v4(),
  );

  HomeGroup toDomain(HomeGroupRecord record) => HomeGroup(
    id: record.id,
    name: record.name,
    emoji: record.emoji,
    currencyCode: record.currencyCode,
    participants: List<String>.unmodifiable(record.participants),
    stableId: record.stableId,
    remoteState: GroupRemoteState.values.firstWhere(
      (value) => value.name == record.remoteState,
      orElse: () => GroupRemoteState.notConfirmed,
    ),
  );
}
