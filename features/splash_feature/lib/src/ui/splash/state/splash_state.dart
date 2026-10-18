part of 'splash_cubit.dart';

enum SplashStatus { loading, loaded, failed }

@freezed
abstract class SplashState with _$SplashState {
  const factory SplashState({@Default(SplashStatus.loading) SplashStatus status}) = _SplashState;
}
