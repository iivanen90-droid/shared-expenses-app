import 'package:common/common.dart';
import 'package:flutter_test/flutter_test.dart';

class _Cubit extends SafeCubitWrapper<int> {
  _Cubit() : super(0);
  void complete() => emit(1);
}

void main() {
  test('a delayed UI update after disposal does not throw', () async {
    final cubit = _Cubit();
    await cubit.close();
    expect(cubit.complete, returnsNormally);
    expect(cubit.state, 0);
  });
}
