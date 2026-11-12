import 'dart:async';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_feature/src/domain/entity/home_group.dart';
import 'package:home_feature/src/domain/interactor/home_groups_interactor.dart';
import 'package:home_feature/src/domain/repository/home_groups_repository.dart';
import 'package:home_feature/src/ui/home/home_analytics.dart';

part 'home_cubit.freezed.dart';
part 'home_state.dart';

class HomeCubit extends SafeCubitWrapper<HomeState> {
  HomeCubit({required this._analytics, required this._interactor}) : super(const HomeState());

  final HomeAnalytics _analytics;
  final HomeGroupsInteractor _interactor;
  StreamSubscription<Either<GroupsStorageFailure, List<HomeGroup>>>? _subscription;

  void initialize() {
    _analytics.onOpened();
    retry();
  }

  void retry() {
    if (isClosed || _subscription != null) return;
    emit(const HomeState());
    _subscription = _interactor.watchGroups().listen(
      (result) => result.match(
        (_) => emit(const HomeState(status: HomeStatus.failed)),
        (groups) => emit(HomeState(status: HomeStatus.loaded, groups: groups)),
      ),
      onDone: () => _subscription = null,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
