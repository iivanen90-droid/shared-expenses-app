import 'package:common/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_feature/src/ui/home/home_analytics.dart';
part 'home_cubit.freezed.dart';
part 'home_state.dart';

class HomeCubit extends SafeCubitWrapper<HomeState> {
  HomeCubit({required this._analytics}) : super(const HomeState());
  final HomeAnalytics _analytics;
  void load() {
    if (isClosed) return;
    _analytics.onOpened();
    emit(state.copyWith(status: HomeStatus.loaded));
  }
}
