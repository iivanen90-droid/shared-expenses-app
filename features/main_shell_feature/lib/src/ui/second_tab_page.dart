import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class SecondTabPage extends StatelessWidget {
  const SecondTabPage({required this.onOpenDetails, super.key});
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              identifier: 'second_tab_title',
              child: Text(LocaleKeys.secondTab.tr(context: context), style: context.texts.title),
            ),
            Semantics(
              identifier: 'second_open_details',
              button: true,
              child: TextButton(
                onPressed: onOpenDetails,
                child: Text(LocaleKeys.openDetails.tr(context: context)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
