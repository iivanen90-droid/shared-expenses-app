import 'dart:async';

import 'package:core/src/auth/auth_service.dart';

/// Account state is independent from commands that sign in or sign out.
abstract interface class AuthSessionSource {
  AuthenticationSnapshot get current;
  AuthenticationProfile? get currentProfile;
  Stream<AuthenticationSnapshot> watchChanges();
}

/// Written by the SDK adapter; features receive only AuthSessionSource.
final class AuthSessionStore implements AuthSessionSource {
  AuthenticationSnapshot _current = (session: AuthenticationStatus.unconfigured, failure: null);
  @override
  AuthenticationProfile? currentProfile;
  final _changes = StreamController<AuthenticationSnapshot>.broadcast();

  @override
  AuthenticationSnapshot get current => _current;
  @override
  Stream<AuthenticationSnapshot> watchChanges() => _changes.stream;

  void update(AuthenticationStatus session, {AuthenticationFailure? failure, AuthenticationProfile? profile}) {
    currentProfile = session == AuthenticationStatus.signedIn ? profile : null;
    _current = (session: session, failure: failure);
    _changes.add(_current);
  }

  Future<void> close() => _changes.close();
}
