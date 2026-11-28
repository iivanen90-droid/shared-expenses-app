import 'package:core/core.dart';
import 'package:main_shell_feature/src/domain/repository/profile_repository.dart';

abstract interface class ProfileSource {
  ProfileSnapshot get current;
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch();
  Future<Either<AuthenticationFailure, Unit>> signOut();
  Future<void> saveLanguage(AppLanguage language);
}

final class ProfileSourceImpl implements ProfileSource {
  const ProfileSourceImpl({required this._auth, required this._sessions, required this._languages});
  final AuthService _auth;
  final AuthSessionSource _sessions;
  final LanguagePreferences _languages;
  @override
  ProfileSnapshot get current {
    final account = _sessions.current;
    return (
      session: account.session,
      profile: account.session == AuthenticationStatus.signedIn ? _sessions.currentProfile : null,
      failure: account.failure,
    );
  }

  @override
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch() => _sessions.watchChanges().map((_) => Right(current));
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() => _auth.signOut();
  @override
  Future<void> saveLanguage(AppLanguage language) => _languages.save(language);
}
