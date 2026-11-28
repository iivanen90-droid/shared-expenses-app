import 'dart:async';

import 'package:auth_feature/src/data/repository/auth_repository_impl.dart';
import 'package:auth_feature/src/data/repository/auth_session_repository_impl.dart';
import 'package:core/core.dart';
import 'package:auth_feature/src/domain/interactor/auth_interactor.dart';
import 'package:auth_feature/src/domain/interactor/auth_session_interactor.dart';
import 'package:auth_feature/src/ui/auth/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _Gateway gateway;
  late AuthRepositoryImpl repository;
  setUp(() {
    gateway = _Gateway();
    repository = AuthRepositoryImpl(
      service: gateway,
      sessions: AuthSessionRepositoryImpl(source: gateway),
    );
  });
  tearDown(() async {
    if (!gateway.launch.isCompleted) gateway.launch.complete(const Right(unit));
    await repository.signOut();
    await gateway.updates.close();
  });

  test('browser launch alone does not finish sign-in', () async {
    var finished = false;
    final operation = repository.signIn(source: AuthSource.google).then((result) {
      finished = true;
      return result;
    });
    gateway.launch.complete(const Right(unit));
    await flush();
    expect(finished, isFalse);
    gateway.publish(const Right(AuthenticationStatus.signedIn));
    expect((await operation).isRight(), isTrue);
    expect(gateway.updates.hasListener, isFalse);
  });
  test('subscribes before launch and does not miss an immediate session', () async {
    gateway.onLaunch = () => gateway.publish(const Right(AuthenticationStatus.signedIn));
    gateway.launch.complete(const Right(unit));
    expect((await repository.signIn(source: AuthSource.google)).isRight(), isTrue);
  });
  test('a failed launch completes with a safe failure', () async {
    gateway.launch.complete(const Left(AuthenticationFailure(AuthenticationFailureKind.connection)));
    final result = await repository.signIn(source: AuthSource.google);
    expect(result.getLeft().toNullable()?.kind, AuthenticationFailureKind.connection);
  });
  test('duplicate calls share one browser launch', () async {
    final first = repository.signIn(source: AuthSource.google);
    final second = repository.signIn(source: AuthSource.google);
    expect(gateway.launches, 1);
    gateway.launch.complete(const Right(unit));
    gateway.publish(const Right(AuthenticationStatus.signedIn));
    expect((await first).isRight(), isTrue);
    expect((await second).isRight(), isTrue);
  });
  test('cancel waits for a late launch and ignores its signed-in event', () async {
    final operation = repository.signIn(source: AuthSource.google);
    final cancelling = repository.signOut();
    await flush();
    expect(gateway.signOuts, 0);
    gateway.publish(const Right(AuthenticationStatus.signedIn));
    gateway.launch.complete(const Right(unit));
    expect((await cancelling).isRight(), isTrue);
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
    expect(gateway.current.session, AuthenticationStatus.signedOut);
  });
  test('early signed-in event still allows cancellation before launch finishes', () async {
    final operation = repository.signIn(source: AuthSource.google);
    gateway.publish(const Right(AuthenticationStatus.signedIn));
    await flush();
    final cleanup = repository.signOut();
    gateway.launch.complete(const Right(unit));
    await cleanup;
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
    expect(gateway.signOuts, 1);
    expect(gateway.current.session, AuthenticationStatus.signedOut);
  });

  test('duplicate callers wait for the same final operation and cancellation', () async {
    final first = repository.signIn(source: AuthSource.google);
    final second = repository.signIn(source: AuthSource.google);
    expect(identical(first, second), isTrue);
    var finished = false;
    second.then((_) => finished = true);
    gateway.publish(const Right(AuthenticationStatus.signedIn));
    await flush();
    expect(finished, isFalse);
    final cancelling = repository.signOut();
    gateway.launch.complete(const Right(unit));
    await cancelling;
    expect((await first).getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
    expect((await second).getLeft().toNullable()?.kind, AuthenticationFailureKind.cancelled);
  });

  test('early success cannot hide a failed cancellation cleanup', () async {
    final operation = repository.signIn(source: AuthSource.google);
    gateway.publish(const Right(AuthenticationStatus.signedIn));
    await flush();
    gateway.cleanupResult = const Left(AuthenticationFailure(AuthenticationFailureKind.storage));
    final cancelling = repository.signOut();
    gateway.launch.complete(const Right(unit));
    await cancelling;
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.storage);
    expect(gateway.current.session, AuthenticationStatus.signedIn);
  });

  test('failed cleanup returns its error and preserves the active session', () async {
    final operation = repository.signIn(source: AuthSource.google);
    gateway.cleanupResult = const Left(AuthenticationFailure(AuthenticationFailureKind.storage));
    final cancelling = repository.signOut();
    gateway.publish(const Right(AuthenticationStatus.signedIn));
    gateway.launch.complete(const Right(unit));
    expect((await cancelling).isLeft(), isTrue);
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.storage);
    expect(gateway.current.session, AuthenticationStatus.signedIn);
  });
  test('a storage failure snapshot cannot be mistaken for successful authentication', () async {
    final operation = repository.signIn(source: AuthSource.google);
    gateway.launch.complete(const Right(unit));
    gateway.current = (
      session: AuthenticationStatus.signedIn,
      failure: const AuthenticationFailure(AuthenticationFailureKind.storage),
    );
    gateway.updates.add(gateway.current);
    expect((await operation).getLeft().toNullable()?.kind, AuthenticationFailureKind.storage);
  });
  test('closing the actual Cubit cancels an early-confirmed pending browser launch', () async {
    final cubit = AuthCubit(
      interactor: AuthInteractorImpl(repository: repository),
      sessions: AuthSessionInteractorImpl(repository: AuthSessionRepositoryImpl(source: gateway)),
    )..initialize();
    final operation = cubit.signInWithGoogle();
    gateway.publish(const Right(AuthenticationStatus.signedIn));
    await flush();
    final closing = cubit.close();
    gateway.launch.complete(const Right(unit));
    await closing;
    await operation;
    expect(cubit.isClosed, isTrue);
    expect(gateway.signOuts, 1);
    expect(gateway.current.session, AuthenticationStatus.signedOut);
    expect(gateway.updates.hasListener, isFalse);
  });
}

class _Gateway implements AuthService, AuthSessionSource {
  @override
  AuthenticationProfile? get currentProfile => null;
  final updates = StreamController<AuthenticationSnapshot>.broadcast();
  final launch = Completer<Either<AuthenticationFailure, Unit>>();
  @override
  AuthenticationSnapshot current = (session: AuthenticationStatus.signedOut, failure: null);
  Either<AuthenticationFailure, Unit> cleanupResult = const Right(unit);
  void Function()? onLaunch;
  int launches = 0;
  int signOuts = 0;
  @override
  Stream<AuthenticationSnapshot> watchChanges() => updates.stream;
  void publish(Either<AuthenticationFailure, AuthenticationStatus> result) {
    result.match(
      (failure) => current = (session: current.session, failure: failure),
      (session) => current = (session: session, failure: null),
    );
    updates.add(current);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<Either<AuthenticationFailure, Unit>> launchSignIn({required AuthSource source}) {
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
