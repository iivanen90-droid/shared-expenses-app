import 'dart:async';

import 'package:auth_feature/src/domain/interactor/auth_interactor.dart';
import 'package:auth_feature/src/domain/repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _Repository repository;
  late AuthInteractorImpl interactor;
  setUp(() {
    repository = _Repository();
    interactor = AuthInteractorImpl(repository: repository);
  });
  tearDown(() async {
    if (!repository.launch.isCompleted) repository.launch.complete(const Right(unit));
    await interactor.dispose();
    await repository.updates.close();
  });

  test('browser launch alone does not finish sign-in', () async {
    var finished = false;
    final operation = interactor.signInWithGoogle().then((result) {
      finished = true;
      return result;
    });
    repository.launch.complete(const Right(unit));
    await flush();
    expect(finished, isFalse);
    repository.publish(const Right(AuthenticationStatus.signedIn));
    expect((await operation).isRight(), isTrue);
    expect(repository.updates.hasListener, isFalse);
  });
  test('subscribes before launch and does not miss an immediate session', () async {
    repository.onLaunch = () => repository.publish(const Right(AuthenticationStatus.signedIn));
    repository.launch.complete(const Right(unit));
    expect((await interactor.signInWithGoogle()).isRight(), isTrue);
  });
  test('a failed launch completes with a safe failure', () async {
    repository.launch.complete(const Left(AuthenticationFailure(AuthenticationFailureKind.connection)));
    final result = await interactor.signInWithGoogle();
    expect(result.getLeft().toNullable()?.kind, AuthenticationFailureKind.connection);
  });
  test('duplicate calls share one browser launch', () async {
    final first = interactor.signInWithGoogle();
    final second = interactor.signInWithGoogle();
    expect(repository.launches, 1);
    repository.launch.complete(const Right(unit));
    repository.publish(const Right(AuthenticationStatus.signedIn));
    expect((await first).isRight(), isTrue);
    expect((await second).isRight(), isTrue);
  });
  test('cancel waits for a late launch and ignores its signed-in event', () async {
    final operation = interactor.signInWithGoogle();
    final cancelling = interactor.cancelSignIn();
    await flush();
    expect(repository.signOuts, 0);
    repository.publish(const Right(AuthenticationStatus.signedIn));
    repository.launch.complete(const Right(unit));
    expect((await cancelling).isRight(), isTrue);
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
    expect(repository.snapshot.session, AuthenticationStatus.signedOut);
  });
  for (final closeOwner in [false, true]) {
    test(
      'early signed-in event still allows ${closeOwner ? 'disposal' : 'cancellation'} before launch finishes',
      () async {
        final operation = interactor.signInWithGoogle();
        repository.publish(const Right(AuthenticationStatus.signedIn));
        await flush();
        final cleanup = closeOwner ? interactor.dispose() : interactor.cancelSignIn();
        repository.launch.complete(const Right(unit));
        await cleanup;
        final result = await operation;
        expect(result.getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
        expect(repository.signOuts, 1);
        expect(repository.snapshot.session, AuthenticationStatus.signedOut);
        expect(repository.updates.hasListener, isFalse);
      },
    );
  }

  test('duplicate callers wait for the same final operation and cancellation', () async {
    final first = interactor.signInWithGoogle();
    final second = interactor.signInWithGoogle();
    expect(identical(first, second), isTrue);
    var finished = false;
    second.then((_) => finished = true);
    repository.publish(const Right(AuthenticationStatus.signedIn));
    await flush();
    expect(finished, isFalse);
    final cancelling = interactor.cancelSignIn();
    repository.launch.complete(const Right(unit));
    await cancelling;
    expect((await first).getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
    expect((await second).getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
  });

  test('early success cannot hide a failed cancellation cleanup', () async {
    final operation = interactor.signInWithGoogle();
    repository.publish(const Right(AuthenticationStatus.signedIn));
    await flush();
    repository.cleanupResult = const Left(AuthenticationFailure(AuthenticationFailureKind.storage));
    final cancelling = interactor.cancelSignIn();
    repository.launch.complete(const Right(unit));
    await cancelling;
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.storage);
    expect(repository.snapshot.session, AuthenticationStatus.signedIn);
  });

  test('failed cleanup returns its error and preserves the active session', () async {
    final operation = interactor.signInWithGoogle();
    repository.cleanupResult = const Left(AuthenticationFailure(AuthenticationFailureKind.storage));
    final cancelling = interactor.cancelSignIn();
    repository.publish(const Right(AuthenticationStatus.signedIn));
    repository.launch.complete(const Right(unit));
    expect((await cancelling).isLeft(), isTrue);
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.storage);
    expect(interactor.snapshot.session, AuthenticationStatus.signedIn);
  });
  test('a storage failure snapshot cannot be mistaken for successful authentication', () async {
    final operation = interactor.signInWithGoogle();
    repository.launch.complete(const Right(unit));
    repository.current = (
      session: AuthenticationStatus.signedIn,
      failure: const AuthenticationFailure(AuthenticationFailureKind.storage),
    );
    repository.updates.add(const Right(AuthenticationStatus.signedIn));
    repository.updates.add(const Left(AuthenticationFailure(AuthenticationFailureKind.storage)));
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.storage);
  });
  test('closing the owner cancels its pending attempt', () async {
    repository.launch.complete(const Right(unit));
    final operation = interactor.signInWithGoogle();
    await interactor.dispose();
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
    expect(repository.signOuts, 1);
    expect(repository.updates.hasListener, isFalse);
  });
}

class _Repository implements AuthRepository {
  final updates = StreamController<Either<AuthenticationFailure, AuthenticationStatus>>.broadcast();
  final launch = Completer<Either<AuthenticationFailure, Unit>>();
  AuthenticationSnapshot current = (session: AuthenticationStatus.signedOut, failure: null);
  Either<AuthenticationFailure, Unit> cleanupResult = const Right(unit);
  void Function()? onLaunch;
  int launches = 0;
  int signOuts = 0;
  @override
  AuthenticationSnapshot get snapshot => current;
  @override
  Stream<Either<AuthenticationFailure, AuthenticationStatus>> watchChanges() => updates.stream;
  void publish(Either<AuthenticationFailure, AuthenticationStatus> result) {
    result.match(
      (failure) => current = (session: current.session, failure: failure),
      (session) => current = (session: session, failure: null),
    );
    updates.add(result);
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() {
    launches++;
    onLaunch?.call();
    return launch.future;
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() async {
    signOuts++;
    if (cleanupResult.isRight()) current = (session: AuthenticationStatus.signedOut, failure: null);
    return cleanupResult;
  }
}
