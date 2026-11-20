import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: context.colors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SplashBrand(),
                if (state.status == SplashStatus.failed) ...[const SizedBox(height: 32), const _StartupError()],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: 'splash_brand',
    label: LocaleKeys.appTitle.tr(context: context),
    excludeSemantics: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.onPrimary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Icon(Icons.groups_outlined, size: 48, color: context.colors.onPrimary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          LocaleKeys.appTitle.tr(context: context),
          textAlign: TextAlign.center,
          style: context.texts.heading.copyWith(color: context.colors.onPrimary),
        ),
      ],
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        LocaleKeys.startupError.tr(context: context),
        textAlign: TextAlign.center,
        style: context.texts.title.copyWith(color: context.colors.onPrimary),
      ),
      Semantics(
        identifier: 'splash_retry',
        container: true,
        button: true,
        child: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: context.colors.onPrimary),
          onPressed: () => context.read<SplashCubit>().load(),
          icon: Icon(context.icons.retry),
          label: Text(LocaleKeys.retry.tr(context: context)),
        ),
      ),
    ],
  );
}
