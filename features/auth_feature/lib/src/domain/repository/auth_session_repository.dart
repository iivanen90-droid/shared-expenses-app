import 'package:core/core.dart';

abstract interface class AuthSessionRepository {
  AuthenticationSnapshot get current;
  Stream<AuthenticationSnapshot> watchChanges();
}
