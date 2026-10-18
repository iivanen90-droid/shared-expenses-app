import 'package:core/core.dart';

abstract interface class StartupRepository {
  Future<Either<Failure, Unit>> checkReadiness();
}
