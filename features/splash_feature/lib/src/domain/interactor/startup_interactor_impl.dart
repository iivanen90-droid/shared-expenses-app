import 'package:core/core.dart';
import 'package:splash_feature/src/data/index.dart';
import 'package:splash_feature/src/domain/interactor/startup_interactor.dart';

final class StartupInteractorImpl implements StartupInteractor {
  const StartupInteractorImpl({required this._repository});
  final StartupRepository _repository;
  @override
  Future<Either<Failure, Unit>> prepare() => _repository.checkReadiness();
}
