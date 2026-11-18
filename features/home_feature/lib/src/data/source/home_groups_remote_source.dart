import 'package:core/core.dart';
import 'package:home_feature/src/data/model/home_group_record.dart';

abstract interface class HomeGroupsRemoteSource {
  String? get currentUserId;
  Future<Either<DatabaseFailure, Unit>> create(HomeGroupRecord group);
}

final class HomeGroupsRemoteSourceImpl implements HomeGroupsRemoteSource {
  const HomeGroupsRemoteSourceImpl({required this._database});
  final RemoteDatabase _database;

  @override
  String? get currentUserId => _database.currentUserId;

  @override
  Future<Either<DatabaseFailure, Unit>> create(HomeGroupRecord group) async {
    // Capture ownership before local persistence; never transfer a group on account change.
    if (group.ownerId.isEmpty || currentUserId != group.ownerId) {
      return const Left(DatabaseFailure(DatabaseFailureKind.authentication));
    }
    final result = await _database.call(
      function: 'create_expense_group',
      parameters: {
        'p_id': group.stableId,
        'p_owner_id': group.ownerId,
        'p_name': group.name,
        'p_emoji': group.emoji,
        'p_currency_code': group.currencyCode,
        'p_participants': group.participants,
      },
    );
    return result.flatMap(
      (id) => id == group.stableId ? const Right(unit) : const Left(DatabaseFailure(DatabaseFailureKind.invalidData)),
    );
  }
}
