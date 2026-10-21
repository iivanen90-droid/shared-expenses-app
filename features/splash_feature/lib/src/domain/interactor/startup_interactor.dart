import 'package:core/core.dart';

abstract interface class StartupInteractor {
  Future<Either<Failure, Unit>> prepare();
}
