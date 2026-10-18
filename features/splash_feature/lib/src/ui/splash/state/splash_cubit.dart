import 'package:common/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:splash_feature/src/domain/index.dart';
import 'package:splash_feature/src/ui/splash/splash_analytics.dart';
part 'splash_cubit.freezed.dart';
part 'splash_state.dart';

class SplashCubit extends SafeCubitWrapper<SplashState> {
  SplashCubit({required this._interactor, required this._analytics}) : super(const SplashState());
  final StartupInteractor _interactor;
  final SplashAnalytics _analytics;
  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(status: SplashStatus.loading));
    _analytics.onOpened();
    final result = await _interactor.prepare();
    result.fold(
      (_) => emit(state.copyWith(status: SplashStatus.failed)),
      (_) => emit(state.copyWith(status: SplashStatus.loaded)),
    );
  }
}
