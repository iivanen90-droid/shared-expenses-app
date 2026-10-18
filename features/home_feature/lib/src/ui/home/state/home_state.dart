part of 'home_cubit.dart';

enum HomeStatus { loading, loaded, failed }

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({@Default(HomeStatus.loading) HomeStatus status}) = _HomeState;
}
