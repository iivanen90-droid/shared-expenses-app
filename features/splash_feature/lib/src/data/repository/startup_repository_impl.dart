import 'package:core/core.dart';
import 'package:splash_feature/src/data/repository/startup_repository.dart';
import 'package:splash_feature/src/data/source/startup_source.dart';
import 'package:splash_feature/src/domain/failure/startup_failure.dart';

final class StartupRepositoryImpl implements StartupRepository {
  const StartupRepositoryImpl({required this._source, required this._crashReporting});
  final StartupSource _source;
  final CrashReportingService _crashReporting;
  @override
  Future<Either<Failure, Unit>> checkReadiness() async {
    try {
      if (await _source.isReady()) return const Right(unit);
      return const Left(StartupFailure());
    } on Object catch (error, stackTrace) {
      _crashReporting.recordError(error, stackTrace);
      return const Left(StartupFailure());
    }
  }
}
