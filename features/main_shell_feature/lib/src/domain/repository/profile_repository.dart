import 'package:core/core.dart';

typedef ProfileSnapshot = ({AuthenticationStatus session, AuthenticationProfile? profile});

final class ProfilePreferencesFailure extends Failure {
  const ProfilePreferencesFailure();
}

abstract interface class ProfileRepository {
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch();
  Future<Either<AuthenticationFailure, Unit>> signOut();
  Future<Either<ProfilePreferencesFailure, Unit>> saveLanguage(AppLanguage language);
}
