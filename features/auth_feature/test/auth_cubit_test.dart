import 'dart:async';

import 'package:auth_feature/src/domain/interactor/auth_interactor.dart';
import 'package:auth_feature/src/ui/auth/auth_cubit.dart';
import 'package:auth_feature/src/ui/auth/auth_state.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _Interactor interactor;
  late AuthCubit cubit;

  setUp(() {
    interactor = _Interactor();
    cubit = AuthCubit(interactor: interactor)..initialize();
  });
  tearDown(() async {
    await cubit.close();
    await interactor.updates.close();
  });

  test('restores a signed-in session and reflects remote sign-out', () async {
    interactor.updates.add(const Right(AuthenticationStatus.signedIn));
    await flush();
    expect(cubit.state.session, AuthenticationStatus.signedIn);
    interactor.updates.add(const Right(AuthenticationStatus.signedOut));
    await flush();
    expect(cubit.state.session, AuthenticationStatus.signedOut);
  });

  test('suppresses duplicate launches and waits for the actual authentication event', () async {
    interactor.updates.add(const Right(AuthenticationStatus.signedOut));
    await flush();
    interactor.launch = Completer<Either<AuthenticationFailure, Unit>>();
    final launch = cubit.signInWithGoogle();
    await cubit.signInWithGoogle();
    expect(interactor.launches, 1);
    interactor.launch!.complete(const Right(unit));
    await launch;
    expect(cubit.state.status, AuthStatus.waitingForGoogle);
    interactor.updates.add(const Right(AuthenticationStatus.signedIn));
    await flush();
    expect(cubit.state.status, AuthStatus.ready);
    expect(cubit.state.session, AuthenticationStatus.signedIn);
  });

  test('cancel clears the pending login and allows another attempt', () async {
    interactor.updates.add(const Right(AuthenticationStatus.signedOut));
    await flush();
    await cubit.signInWithGoogle();
    await cubit.cancelSignIn();
    expect(interactor.signOuts, 1);
    expect(cubit.state.failure, AuthenticationFailureKind.cancelled);
    await cubit.signInWithGoogle();
    expect(interactor.launches, 2);
  });

  test('provider and stream failures expose only a safe retry state', () async {
    interactor.updates.add(const Right(AuthenticationStatus.signedOut));
    await flush();
    interactor.result = const Left(AuthenticationFailure(AuthenticationFailureKind.connection));
    await cubit.signInWithGoogle();
    expect(cubit.state.status, AuthStatus.ready);
    expect(cubit.state.failure, AuthenticationFailureKind.connection);
    interactor.updates.addError(StateError('private-provider-error'));
    await flush();
    expect(cubit.state.failure, AuthenticationFailureKind.connection);
  });

  test('failed sign-out retains the session and retry succeeds', () async {
    interactor.updates.add(const Right(AuthenticationStatus.signedIn));
    await flush();
    interactor.result = const Left(AuthenticationFailure(AuthenticationFailureKind.storage));
    await cubit.signOut();
    expect(cubit.state.session, AuthenticationStatus.signedIn);
    expect(cubit.state.failure, AuthenticationFailureKind.storage);
    interactor.result = const Right(unit);
    await cubit.signOut();
    expect(cubit.state.session, AuthenticationStatus.signedOut);
  });

  test('a response arriving after page disposal does not emit on the closed Cubit', () async {
    interactor.updates.add(const Right(AuthenticationStatus.signedOut));
    await flush();
    interactor.launch = Completer<Either<AuthenticationFailure, Unit>>();
    final launch = cubit.signInWithGoogle();
    await cubit.close();
    interactor.launch!.complete(const Left(AuthenticationFailure(AuthenticationFailureKind.connection)));
    await launch;
    expect(cubit.isClosed, isTrue);
  });

  test('a signed-out event keeps the page busy until the sign-out operation finishes', () async {
    interactor.updates.add(const Right(AuthenticationStatus.signedIn));
    await flush();
    interactor.signOutGate = Completer<Either<AuthenticationFailure, Unit>>();
    final signingOut = cubit.signOut();
    interactor.updates.add(const Right(AuthenticationStatus.signedOut));
    await flush();
    expect(cubit.state.status, AuthStatus.signingOut);
    await cubit.signOut();
    expect(interactor.signOuts, 1);
    interactor.signOutGate!.complete(const Right(unit));
    await signingOut;
    expect(cubit.state.status, AuthStatus.ready);
    expect(cubit.state.session, AuthenticationStatus.signedOut);
  });
}

class _Interactor implements AuthInteractor {
  final updates = StreamController<Either<AuthenticationFailure, AuthenticationStatus>>();
  Either<AuthenticationFailure, Unit> result = const Right(unit);
  Completer<Either<AuthenticationFailure, Unit>>? launch;
  Completer<Either<AuthenticationFailure, Unit>>? signOutGate;
  int launches = 0;
  int signOuts = 0;
  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchStatus() => updates.stream;
  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() async {
    launches++;
    return launch == null ? result : await launch!.future;
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() async {
    signOuts++;
    return signOutGate == null ? result : await signOutGate!.future;
  }
}
