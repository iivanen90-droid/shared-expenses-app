import 'package:core/core.dart';
import 'package:main_shell_feature/src/data/source/profile_source.dart';
import 'package:main_shell_feature/src/domain/repository/profile_repository.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this._source});
  final ProfileSource _source;
  @override
  Stream<Either<AuthenticationFailure, ProfileSnapshot>> watch() async* {
    try {
      yield* _source.watch();
    } on Object {
      yield const Left(AuthenticationFailure(AuthenticationFailureKind.connection));
    }
  }

  @override
  Future<Either<AuthenticationFailure, Unit>> signOut() async {
    try {
      return await _source.signOut();
    } on Object {
      return const Left(AuthenticationFailure(AuthenticationFailureKind.connection));
    }
  }

  @override
  Future<Either<ProfilePreferencesFailure, Unit>> saveLanguage(AppLanguage language) async {
    try {
      await _source.saveLanguage(language);
      return const Right(unit);
    } on Object {
      return const Left(ProfilePreferencesFailure());
    }
  }
}
