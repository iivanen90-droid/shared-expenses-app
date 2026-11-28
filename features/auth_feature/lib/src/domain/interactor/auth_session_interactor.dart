import 'package:core/core.dart';
import 'package:auth_feature/src/domain/repository/auth_session_repository.dart';

abstract interface class AuthSessionInteractor {
  AuthenticationSnapshot get current;
}

final class AuthSessionInteractorImpl implements AuthSessionInteractor {
  const AuthSessionInteractorImpl({required this._repository});
  final AuthSessionRepository _repository;
  @override
  AuthenticationSnapshot get current => _repository.current;
}
