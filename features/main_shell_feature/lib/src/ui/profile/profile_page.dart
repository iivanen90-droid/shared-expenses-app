import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Semantics(
      container: true,
      identifier: 'profile_page',
      label: LocaleKeys.profileTab.tr(context: context),
      child: const SizedBox.expand(),
    ),
  );
}
