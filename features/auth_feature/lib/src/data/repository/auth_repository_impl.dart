import 'dart:async';

import 'package:core/core.dart';
import 'package:auth_feature/src/domain/repository/auth_repository.dart';
import 'package:auth_feature/src/domain/repository/auth_session_repository.dart';

/// Adapts browser launch + account confirmation into one final command result.
final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._service, required this._sessions});
  final AuthService _service;
  final AuthSessionRepository _sessions;
  Future<Either<AuthenticationFailure, Unit>>? _operation;
  Future<Either<AuthenticationFailure, Unit>>? _launch;
  Future<Either<AuthenticationFailure, Unit>>? _cleanup;
  Completer<Either<AuthenticationFailure, Unit>>? _confirmation;

  @override
  Future<Either<AuthenticationFailure, Unit>> signIn({required AuthSource source}) {
    final pending = _operation;
    if (pending != null) return pending;
    final cleanup = _cleanup;
    if (cleanup != null) {
      return cleanup.then(
        (result) => result.match(
          (failure) => Future.value(Left<AuthenticationFailure, Unit>(failure)),
          (_) => signIn(source: source),
        ),
      );
    }
    final confirmation = Completer<Either<AuthenticationFailure, Unit>>();
    _confirmation = confirmation;
    return _operation = _signIn(source, confirmation).whenComplete(() {
      _operation = null;
      _launch = null;
      _cleanup = null;
      _confirmation = null;
    });
  }

  Future<Either<AuthenticationFailure, Unit>> _signIn(
    AuthSource source,
    Completer<Either<AuthenticationFailure, Unit>> confirmation,
  ) async {
    // Listen before launching so a fast provider response cannot be missed.
    final subscription = _sessions.watchChanges().listen((account) {
      if (_cleanup != null || confirmation.isCompleted) return;
      if (account.failure case final failure?) {
        confirmation.complete(Left(failure));
      } else if (account.session == AuthenticationStatus.signedIn) {
        confirmation.complete(const Right(unit));
      }
    });
    try {
      final launched = await (_launch = _service.launchSignIn(source: source));
      if (launched.isLeft() && !confirmation.isCompleted) confirmation.complete(launched);
      final result = await confirmation.future;
      final cleanup = _cleanup;
      if (cleanup == null) return result;
      // Cleanup has precedence even if an earlier SDK event reported success.
      return (await cleanup).flatMap((_) => const Left(AuthenticationFailure(AuthenticationFailureKind.cancelled)));
    } finally {
      unawaited(subscription.cancel());
    }
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() {
    final cancelsSignIn = _operation != null;
    return _cleanup ??= _clearSession().whenComplete(() {
      if (!cancelsSignIn) _cleanup = null;
    });
  }

  Future<Either<AuthenticationFailure, Unit>> _clearSession() async {
    // Launch and PKCE exchange can finish late; the SDK adapter drains PKCE itself.
    await _launch;
    final result = await _service.signOut();
    final confirmation = _confirmation;
    if (confirmation != null && !confirmation.isCompleted) confirmation.complete(result);
    return result;
  }
}
