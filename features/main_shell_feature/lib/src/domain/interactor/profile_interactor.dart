import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/repository/profile_repository.dart';

abstract interface class ProfileInteractor {
  ProfileSnapshot get current;
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch();
  Future<Either<AuthenticationFailure, Unit>> signOut();
  Future<Either<ProfilePreferencesFailure, Unit>> saveLanguage(AppLanguage language);
}

final class ProfileInteractorImpl implements ProfileInteractor {
  const ProfileInteractorImpl({required this._repository});
  final ProfileRepository _repository;
  @override
  ProfileSnapshot get current => _repository.current;
  @override
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch() => _repository.watch();
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _repository.signOut();
  @override
  Future<Either<ProfilePreferencesFailure, Unit>> saveLanguage(AppLanguage language) =>
      _repository.saveLanguage(language);
}
