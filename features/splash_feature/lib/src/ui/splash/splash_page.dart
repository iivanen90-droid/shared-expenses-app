import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:router/router.dart';
import 'package:splash_feature/src/ui/splash/state/splash_cubit.dart';
import 'package:ui_kit/ui_kit.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<SplashCubit>(
    create: (_) => DependencyProvider.get<SplashCubit>()..load(),
    child: const _SplashView(),
  );
}

class _SplashView extends StatelessWidget {
  const _SplashView();
  @override
  Widget build(BuildContext context) => BlocConsumer<SplashCubit, SplashState>(
    listenWhen: (previous, current) => previous.status != current.status,
    listener: (context, state) {
      if (state.status == SplashStatus.loaded) context.goTo(const HomeRoute());
    },
    builder: (context, state) => Scaffold(
      body: SafeArea(
        child: Center(child: state.status == SplashStatus.failed ? const _StartupError() : const AppLoading()),
      ),
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(LocaleKeys.startupError.tr(context: context), style: context.texts.title),
      Semantics(
        identifier: 'splash_retry',
        container: true,
        button: true,
        child: TextButton.icon(
          onPressed: () => context.read<SplashCubit>().load(),
          icon: Icon(context.icons.retry),
          label: Text(LocaleKeys.retry.tr(context: context)),
        ),
      ),
    ],
  );
}
