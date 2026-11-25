import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main_shell_feature/src/domain/interactor/profile_account_interactor.dart';
import 'package:main_shell_feature/src/ui/profile/profile_account_cubit.dart';
import 'package:main_shell_feature/src/ui/profile/profile_account_state.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _Interactor interactor;
  late ProfileAccountCubit cubit;
  setUp(() {
    interactor = _Interactor();
    cubit = ProfileAccountCubit(interactor: interactor)..initialize();
  });
  tearDown(() async {
    await cubit.close();
    await interactor.updates.close();
  });
  test('Profile follows session changes while mounted', () async {
    expect(cubit.state.session, AuthenticationStatus.signedIn);
    interactor.current = (session: AuthenticationStatus.signedOut, failure: null);
    interactor.updates.add(const Right(AuthenticationStatus.signedOut));
    await flush();
    expect(cubit.state.session, AuthenticationStatus.signedOut);
  });
  test('a session event does not unblock a pending logout', () async {
    final operation = cubit.signOut();
    interactor.current = (session: AuthenticationStatus.signedOut, failure: null);
    interactor.updates.add(const Right(AuthenticationStatus.signedOut));
    await flush();
    expect(cubit.state.status, ProfileAccountStatus.signingOut);
    await cubit.signOut();
    expect(interactor.signOuts, 1);
    interactor.result.complete(const Right(unit));
    await operation;
    expect(cubit.state.status, ProfileAccountStatus.initial);
    expect(cubit.state.session, AuthenticationStatus.signedOut);
  });
  test('failed logout preserves the actual session and permits retry', () async {
    final operation = cubit.signOut();
    interactor.result.complete(const Left(AuthenticationFailure(AuthenticationFailureKind.storage)));
    await operation;
    expect(cubit.state.status, ProfileAccountStatus.error);
    expect(cubit.state.session, AuthenticationStatus.signedIn);
    interactor.result = Completer<Either<AuthenticationFailure, Unit>>();
    final retry = cubit.signOut();
    interactor.current = (session: AuthenticationStatus.signedOut, failure: null);
    interactor.result.complete(const Right(unit));
    await retry;
    expect(interactor.signOuts, 2);
    expect(cubit.state.session, AuthenticationStatus.signedOut);
  });
  test('late logout completion after disposal cannot emit', () async {
    final operation = cubit.signOut();
    await cubit.close();
    interactor.result.complete(const Right(unit));
    await operation;
    expect(cubit.isClosed, isTrue);
  });
}

class _Interactor implements ProfileAccountInteractor {
  AuthenticationSnapshot current = (session: AuthenticationStatus.signedIn, failure: null);
  final updates = StreamController<Either<AuthenticationFailure, AuthenticationStatus>>.broadcast();
  Completer<Either<AuthenticationFailure, Unit>> result = Completer();
  int signOuts = 0;
  @override
  AuthenticationSnapshot get snapshot => current;
  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => updates.stream;
  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() {
    signOuts++;
    return result.future;
  }
}
