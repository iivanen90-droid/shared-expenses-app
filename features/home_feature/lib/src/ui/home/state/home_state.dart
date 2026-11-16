part of 'home_cubit.dart';

enum HomeStatus { loading, loaded, failed }

@Freezed(makeCollectionsUnmodifiable: false)
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(HomeStatus.loading) HomeStatus status,
    @Default(<HomeGroup>[]) List<HomeGroup> groups,
  }) = _HomeState;
}
