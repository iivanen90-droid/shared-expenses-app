import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Empty navigation destination until tab-specific product screens are approved.
class TabDetailsPage extends StatelessWidget {
  const TabDetailsPage({required this.identifier, super.key});
  final String identifier;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(LocaleKeys.details.tr(context: context))),
    body: SafeArea(
      child: Center(
        child: Semantics(
          identifier: identifier,
          child: Text(LocaleKeys.details.tr(context: context), style: context.texts.title),
        ),
      ),
    ),
  );
}
