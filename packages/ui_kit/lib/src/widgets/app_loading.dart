import 'package:flutter/material.dart';
import 'package:ui_kit/src/generated/assets.gen.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    identifier: 'splash_loading',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [Assets.icons.startup.svg(), const CircularProgressIndicator()],
    ),
  );
}
