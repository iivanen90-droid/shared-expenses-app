import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NewTricountPage extends StatelessWidget {
  const NewTricountPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Semantics(
        identifier: 'new_tricount_title',
        child: Text(LocaleKeys.newTricount.tr(context: context)),
      ),
    ),
  );
}
