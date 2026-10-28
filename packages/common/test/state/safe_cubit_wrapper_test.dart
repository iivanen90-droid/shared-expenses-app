import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter_test/flutter_test.dart';

class _Cubit extends SafeCubitWrapper<int> {
  _Cubit() : super(0);
  void complete() => emit(1);
  Future<void> completeAfter(Future<void> pending) async {
    await pending;
    emit(1);
  }
}

void main() {
  test('state updates are delivered while the cubit is open', () async {
    final cubit = _Cubit();
    addTearDown(cubit.close);
    final update = expectLater(cubit.stream, emits(1));
    cubit.complete();
    await update;
    expect(cubit.state, 1);
  });
  test('asynchronous completion after closing is safely ignored', () async {
    final cubit = _Cubit();
    final operation = Completer<void>();
    final update = cubit.completeAfter(operation.future);
    await cubit.close();
    operation.complete();
    await update;
    expect(cubit.state, 0);
  });
  test('a delayed UI update after disposal does not throw', () async {
    final cubit = _Cubit();
    await cubit.close();
    expect(cubit.complete, returnsNormally);
    expect(cubit.state, 0);
  });
}
