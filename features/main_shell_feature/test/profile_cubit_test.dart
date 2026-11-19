import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_interactor.dart';
import 'package:main_shell_feature/src/domain/repository/profile_repository.dart';
import 'package:main_shell_feature/src/ui/profile/profile_cubit.dart';
import 'package:main_shell_feature/src/ui/profile/profile_state.dart';

void main() {
  late _Interactor interactor;
  late ProfileCubit cubit;
  Future<void> flush() => Future<void>.delayed(Duration.zero);
  setUp(() async {
    interactor = _Interactor();
    cubit = ProfileCubit(interactor: interactor)..initialize(AppLanguage.uk);
    await flush();
  });
  tearDown(() async {
    await cubit.close();
    await interactor.updates.close();
  });
  test('exposes current profile without including personal fields in diagnostic strings', () {
    expect(cubit.state.profile?.name, 'Test Person');
    expect(cubit.state.profile?.email, 'test@example.invalid');
    expect(cubit.state.toString(), isNot(contains('Test Person')));
    expect(cubit.state.profile.toString(), isNot(contains('test@example.invalid')));
  });
  test('language changes only after persistence succeeds; failure retains previous choice', () async {
    interactor.failLanguage = true;
    await cubit.changeLanguage(AppLanguage.en);
    expect(cubit.state.language, AppLanguage.uk);
    expect(cubit.state.failure, ProfileFailure.language);
    interactor.failLanguage = false;
    await cubit.changeLanguage(AppLanguage.en);
    expect(cubit.state.language, AppLanguage.en);
    expect(cubit.state.failure, isNull);
  });
  test('duplicate sign-out is ignored and failed sign-out keeps account available for retry', () async {
    interactor.pendingLogout = Completer();
    final first = cubit.signOut();
    await cubit.signOut();
    expect(interactor.logouts, 1);
    interactor.pendingLogout!.complete(const Left(AuthenticationFailure(AuthenticationFailureKind.storage)));
    await first;
    expect(cubit.state.session, AuthenticationStatus.signedIn);
    expect(cubit.state.profile?.name, 'Test Person');
    expect(cubit.state.failure, ProfileFailure.logout);
    interactor.pendingLogout = null;
    await cubit.signOut();
    expect(cubit.state.status, ProfileStatus.signedOut);
    expect(cubit.state.profile, isNull);
    expect(cubit.state.language, AppLanguage.uk);
  });
  test('a remote session removal immediately clears displayed identity', () async {
    interactor.updates.add(const Right((session: AuthenticationStatus.signedOut, profile: null)));
    await flush();
    expect(cubit.state.profile, isNull);
    expect(cubit.state.session, AuthenticationStatus.signedOut);
  });
  test('a completion after disposal is ignored', () async {
    interactor.pendingLogout = Completer();
    final logout = cubit.signOut();
    await cubit.close();
    interactor.pendingLogout!.complete(const Right(unit));
    await logout;
    expect(cubit.isClosed, isTrue);
  });
}

class _Interactor implements ProfileInteractor {
  final updates = StreamController<Either<AuthenticationFailure, ProfileSnapshot>>.broadcast();
  bool failLanguage = false;
  int logouts = 0;
  Completer<Either<AuthenticationFailure, Unit>>? pendingLogout;
  @override
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch() async* {
    yield const Right((
      session: AuthenticationStatus.signedIn,
      profile: AuthenticationProfile(name: 'Test Person', email: 'test@example.invalid'),
    ));
    yield* updates.stream;
  }

  @override
  Future<Either<ProfilePreferencesFailure, Unit>> saveLanguage(AppLanguage language) async =>
      failLanguage ? const Left(ProfilePreferencesFailure()) : const Right(unit);
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() {
    logouts++;
    return pendingLogout?.future ?? Future.value(const Right(unit));
  }
}
