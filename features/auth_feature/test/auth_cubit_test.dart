import 'dart:async';

import 'package:auth_feature/src/domain/interactor/auth_interactor.dart';
import 'package:auth_feature/src/domain/interactor/auth_session_interactor.dart';
import 'package:auth_feature/src/ui/auth/auth_cubit.dart';
import 'package:auth_feature/src/ui/auth/auth_state.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _Interactor interactor;
  late AuthCubit cubit;
  setUp(() {
    interactor = _Interactor();
    cubit = AuthCubit(interactor: interactor, sessions: interactor)..initialize();
  });
  tearDown(() => cubit.close());

  test('reads the initial session without a screen subscription', () {
    expect(cubit.state.status, AuthStatus.initial);
    expect(cubit.state.canSignIn, isTrue);
    interactor.current = (session: AuthenticationStatus.signedIn, failure: null);
    cubit.initialize();
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.canSignIn, isFalse);
  });
  test('loading blocks duplicate attempts until the final result', () async {
    final operation = cubit.signInWithGoogle();
    await cubit.signInWithGoogle();
    expect(interactor.launches, 1);
    expect(cubit.state.status, AuthStatus.loading);
    interactor.current = (session: AuthenticationStatus.signedIn, failure: null);
    interactor.result.complete(const Right(unit));
    await operation;
    expect(cubit.state.status, AuthStatus.authenticated);
  });
  test('a failure has an explicit error state and allows retry', () async {
    final operation = cubit.signInWithGoogle();
    interactor.result.complete(const Left(AuthenticationFailure(AuthenticationFailureKind.connection)));
    await operation;
    expect(cubit.state.status, AuthStatus.error);
    expect(cubit.state.failure, AuthenticationFailureKind.connection);
    expect(cubit.state.canSignIn, isTrue);
  });
  test('cancellation is separate from logout and duplicate cancellation is ignored', () async {
    final operation = cubit.signInWithGoogle();
    await cubit.cancelSignIn();
    await cubit.cancelSignIn();
    await operation;
    expect(interactor.cancellations, 1);
    expect(cubit.state.status, AuthStatus.initial);
    expect(cubit.state.failure, AuthenticationFailureKind.cancelled);
    expect(cubit.state.canSignIn, isTrue);
  });
  test('storage failure preserves the real active session for Profile recovery', () async {
    final operation = cubit.signInWithGoogle();
    const failure = AuthenticationFailure(AuthenticationFailureKind.storage);
    interactor.current = (session: AuthenticationStatus.signedIn, failure: failure);
    interactor.result.complete(const Left(failure));
    await operation;
    expect(cubit.state.status, AuthStatus.error);
    expect(cubit.state.session, AuthenticationStatus.signedIn);
    expect(cubit.state.canSignIn, isFalse);
  });
  test('closing cancels pending work and prevents late state emissions', () async {
    final operation = cubit.signInWithGoogle();
    await cubit.close();
    await operation;
    expect(cubit.isClosed, isTrue);
    expect(interactor.cancellations, 1);
  });
}

class _Interactor implements AuthInteractor, AuthSessionInteractor {
  @override
  AuthenticationSnapshot current = (session: AuthenticationStatus.signedOut, failure: null);
  final result = Completer<Either<AuthenticationFailure, Unit>>();
  int launches = 0;
  int cancellations = 0;
  @override
  Future<Either<AuthenticationFailure, Unit>> signIn({required AuthSource source}) {
    launches++;
    return result.future;
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() async {
    cancellations++;
    if (!result.isCompleted) result.complete(const Left(AuthenticationFailure(AuthenticationFailureKind.cancelled)));
    return const Right(unit);
  }
}
