import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/repository/profile_repository.dart';

abstract interface class ProfileSource {
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch();
  Future<Either<AuthenticationFailure, Unit>> signOut();
  Future<void> saveLanguage(AppLanguage language);
}

final class ProfileSourceImpl implements ProfileSource {
  const ProfileSourceImpl({required this._auth, required this._languages});
  final AuthService _auth;
  final LanguagePreferences _languages;
  @override
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch() => _auth.watchStatus().map(
    (result) => result.map(
      (session) => (session: session, profile: session == AuthenticationStatus.signedIn ? _auth.currentProfile : null),
    ),
  );
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _auth.signOut();
  @override
  Future<void> saveLanguage(AppLanguage language) => _languages.save(language);
}
