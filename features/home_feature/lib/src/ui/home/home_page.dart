import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_feature/src/ui/home/state/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:router/router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocProvider<HomeCubit>(create: (_) => DependencyProvider.get<HomeCubit>()..load(), child: const _HomeView());
}

class _HomeView extends StatelessWidget {
  const _HomeView();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              identifier: 'home_title',
              child: Text(LocaleKeys.appTitle.tr(context: context), style: context.texts.title),
            ),
            Semantics(
              identifier: 'home_open_details',
              button: true,
              child: TextButton(
                onPressed: () => context.pushTo<void>(const HomeDetailsRoute()),
                child: Text(LocaleKeys.openDetails.tr(context: context)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
