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
  _PendingSignIn? _attempt;
  bool _disposed = false;

  @override
  AuthenticationSnapshot get snapshot => _repository.snapshot;

  @override
  Future<Either<AuthenticationFailure, Unit>> signInWithGoogle() {
    if (_disposed) return Future.value(const Left(AuthenticationFailure(AuthenticationFailureKind.cancelled)));
    if (_attempt case final attempt?) return attempt.operation;
    final attempt = _PendingSignIn();
    _attempt = attempt;
    return attempt.operation = _runSignIn(attempt);
  }

  Future<Either<AuthenticationFailure, Unit>> _runSignIn(_PendingSignIn attempt) async {
    // Subscribe before browser launch; do not replay errors from an earlier attempt.
    final subscription = _repository.watchChanges().listen((result) {
      if (attempt.isCancelling) return;
      result.match((failure) => attempt.complete(Left(failure)), (session) {
        if (session == AuthenticationStatus.signedIn) {
          final failure = _repository.snapshot.failure;
          attempt.complete(failure == null ? const Right(unit) : Left(failure));
        }
      });
    });
    try {
      attempt.launch = _repository.signInWithGoogle();
      final launched = await attempt.launch;
      if (!attempt.isCancelling) launched.match((failure) => attempt.complete(Left(failure)), (_) {});
      final result = await attempt.authResult.future;
      // An SDK event is not the end of this operation: launch/cleanup may still be pending.
      final cancellation = attempt.cancellation;
      if (cancellation == null) return result;
      return (await cancellation).flatMap(
        (_) => const Left(AuthenticationFailure(AuthenticationFailureKind.cancelled)),
      );
    } finally {
      // Detach the in-memory listener immediately; its cleanup must not hold the UI result.
      unawaited(subscription.cancel());
      if (identical(_attempt, attempt)) _attempt = null;
    }
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> cancelSignIn() {
    final attempt = _attempt;
    if (attempt == null) return Future.value(const Right(unit));
    return attempt.cancellation ??= _cancel(attempt);
  }

  Future<Either<AuthenticationFailure, Unit>> _cancel(_PendingSignIn attempt) async {
    // Browser launch can finish late too. Drain it before clearing its possible session.
    await attempt.launch;
    final result = await _repository.signOut();
    // Wake the operation; it applies cancellation precedence in one place above.
    attempt.complete(result);
    return result;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await cancelSignIn();
  }
}

final class _PendingSignIn {
  final authResult = Completer<Either<AuthenticationFailure, Unit>>();
  late final Future<Either<AuthenticationFailure, Unit>> operation;
  late final Future<Either<AuthenticationFailure, Unit>> launch;
  Future<Either<AuthenticationFailure, Unit>>? cancellation;
  bool get isCancelling => cancellation != null;

  void complete(Either<AuthenticationFailure, Unit> value) {
    if (!authResult.isCompleted) authResult.complete(value);
  }
}
