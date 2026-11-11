import 'package:common/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';
import 'package:home_feature/src/ui/home/home_analytics.dart';

part 'home_cubit.freezed.dart';
part 'home_state.dart';

class HomeCubit extends SafeCubitWrapper<HomeState> {
  HomeCubit({required this._analytics, required this._interactor}) : super(const HomeState());

  final HomeAnalytics _analytics;
  final HomeGroupsInteractor _interactor;

  void initialize() {
    if (isClosed) return;
    _analytics.onOpened();
    emit(HomeState(status: HomeStatus.loaded, groups: List<HomeGroup>.unmodifiable(_interactor.getGroups())));
  }
}
