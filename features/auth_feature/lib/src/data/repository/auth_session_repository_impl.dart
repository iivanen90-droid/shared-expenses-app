import 'package:core/core.dart';
import 'package:auth_feature/src/domain/repository/auth_session_repository.dart';

final class AuthSessionRepositoryImpl implements AuthSessionRepository {
  const AuthSessionRepositoryImpl({required this._source});
  final AuthSessionSource _source;
  @override
  AuthenticationSnapshot get current => _source.current;
  @override
  Stream<AuthenticationSnapshot> watchChanges() => _source.watchChanges();
}
