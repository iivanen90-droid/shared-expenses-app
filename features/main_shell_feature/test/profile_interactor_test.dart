import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main_shell_feature/src/data/source/profile_source.dart';
import 'package:main_shell_feature/src/data/repository/profile_repository_impl.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_interactor.dart';

void main() {
  test('signed-out snapshots exclude stale profile fields', () async {
    final auth = _Auth();
    final interactor = ProfileInteractorImpl(
      repository: ProfileRepositoryImpl(
        source: ProfileSourceImpl(auth: auth, languages: _Languages()),
      ),
    );
    final snapshot = (await interactor.watch().first).getOrElse((_) => throw StateError('profile'));
    expect(snapshot.session, AuthenticationStatus.signedOut);
    expect(snapshot.profile, isNull);
  });
  test('storage and unexpected logout exceptions become safe typed failures', () async {
    final interactor = ProfileInteractorImpl(
      repository: ProfileRepositoryImpl(
        source: ProfileSourceImpl(auth: _Auth(), languages: _Languages()..fail = true),
      ),
    );
    expect((await interactor.saveLanguage(AppLanguage.uk)).isLeft(), isTrue);
    expect((await interactor.signOut()).isLeft(), isTrue);
  });
}

class _Languages implements LanguagePreferences {
  bool fail = false;
  @override
  Future<AppLanguage> load({AppLanguage fallback = AppLanguage.en}) async => fallback;
  @override
  Future<void> save(AppLanguage language) async {
    if (fail) throw StateError('Test write failure');
  }
}

class _Auth implements AuthService {
  @override
  AuthenticationProfile? get currentProfile =>
      const AuthenticationProfile(name: 'Old User', email: 'old@example.invalid');
  @override
  Future<void> initialize() async {}
  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() =>
      Stream.value(const Right(AuthenticationStatus.signedOut));
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() async => throw StateError('Test logout failure');
  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() async => const Right(unit);
}
