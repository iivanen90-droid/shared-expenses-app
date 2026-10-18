import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:splash_feature/src/data/index.dart';
import 'package:splash_feature/src/domain/interactor/startup_interactor_impl.dart';
import 'package:splash_feature/src/domain/index.dart';

class _Repository extends Mock implements StartupRepository {}

void main() {
  test('startup success is passed to the UI layer', () async {
    final repository = _Repository();
    when(repository.checkReadiness).thenAnswer((_) async => const Right(unit));
    final result = await StartupInteractorImpl(repository: repository).prepare();
    expect(result.isRight(), isTrue);
    verify(repository.checkReadiness).called(1);
  });
  test('startup failure remains a typed failure', () async {
    final repository = _Repository();
    when(repository.checkReadiness).thenAnswer((_) async => const Left(StartupFailure()));
    final result = await StartupInteractorImpl(repository: repository).prepare();
    expect(result.isLeft(), isTrue);
  });
}
