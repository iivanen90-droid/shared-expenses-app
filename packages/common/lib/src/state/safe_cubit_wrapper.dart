import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SafeCubitWrapper<State> extends Cubit<State> {
  SafeCubitWrapper(super.initialState);
  @override
  void emit(State state) {
    if (!isClosed) super.emit(state);
  }
}
