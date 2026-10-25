import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestFailure extends Failure {
  const _TestFailure();
}

void main() {
  test('the public core API exposes a failure as Left', () {
    const failure = _TestFailure();
    const Either<Failure, String> result = Left(failure);
    var successCalled = false;
    final received = result.fold<Failure?>((error) => error, (_) {
      successCalled = true;
      return null;
    });
    expect(received, same(failure));
    expect(successCalled, isFalse);
  });

  test('the public core API exposes a successful value as Right', () {
    const Either<Failure, String> result = Right('ready');
    var failureCalled = false;
    final received = result.fold<String?>((_) {
      failureCalled = true;
      return null;
    }, (value) => value);
    expect(received, 'ready');
    expect(failureCalled, isFalse);
  });
}
