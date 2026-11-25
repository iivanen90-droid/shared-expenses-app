import 'dart:async';

import 'package:core/core.dart';
import 'package:auth_feature/src/domain/repository/auth_repository.dart';

abstract interface class AuthInteractor {
  AuthenticationSnapshot get snapshot;
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle();
  Future<Either<AuthenticationFailure, Unit>> cancelSignIn();
  Future<void> dispose();
}

/// Owns one screen's sign-in attempt; SDK callback and persistence safety stay in core.
final class AuthInteractorImpl implements AuthInteractor {
  AuthInteractorImpl({required this._repository});
  final AuthRepository _repository;
  _SignInAttempt? _attempt;
  bool _disposed = false;

  @override
  AuthenticationSnapshot get snapshot => _repository.snapshot;

  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() {
    if (_disposed) return Future.value(const Left(AuthenticationFailure(AuthenticationFailureKind.cancelled)));
    if (_attempt case final attempt?) return attempt.result.future;
    final attempt = _SignInAttempt();
    _attempt = attempt;
    return _runSignIn(attempt);
  }

  Future<Either<AuthenticationFailure, Unit>> _runSignIn(_SignInAttempt attempt) async {
    // Subscribe before browser launch; do not replay errors from an earlier attempt.
    final subscription = _repository.watchChanges().listen((result) {
      if (attempt.cancelling) return;
      result.match((failure) => attempt.complete(Left(failure)), (session) {
        if (session == AuthenticationStatus.signedIn) {
          final failure = _repository.snapshot.failure;
          attempt.complete(failure == null ? const Right(unit) : Left(failure));
        }
      });
    });
    try {
      final launch = _repository.signInWithGoogle();
      attempt.launch = launch;
      final launched = await launch;
      if (!attempt.cancelling) launched.match((failure) => attempt.complete(Left(failure)), (_) {});
      return await attempt.result.future;
    } finally {
      // Detach the in-memory listener immediately; its cleanup must not hold the UI result.
      unawaited(subscription.cancel());
      if (identical(_attempt, attempt)) _attempt = null;
    }
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> cancelSignIn() {
    final attempt = _attempt;
    if (attempt == null || attempt.result.isCompleted) return Future.value(const Right(unit));
    attempt.cancelling = true;
    return attempt.cancellation ??= _cancel(attempt);
  }

  Future<Either<AuthenticationFailure, Unit>> _cancel(_SignInAttempt attempt) async {
    // Browser launch can finish late too. Drain it before clearing its possible session.
    await attempt.launch;
    final result = await _repository.signOut();
    attempt.complete(
      result.match(
        (failure) => Left(failure),
        (_) => const Left(AuthenticationFailure(AuthenticationFailureKind.cancelled)),
      ),
    );
    return result;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await cancelSignIn();
  }
}

final class _SignInAttempt {
  final result = Completer<Either<AuthenticationFailure, Unit>>();
  Future<Either<AuthenticationFailure, Unit>>? launch;
  Future<Either<AuthenticationFailure, Unit>>? cancellation;
  bool cancelling = false;

  void complete(Either<AuthenticationFailure, Unit> value) {
    if (!result.isCompleted) result.complete(value);
  }
}
