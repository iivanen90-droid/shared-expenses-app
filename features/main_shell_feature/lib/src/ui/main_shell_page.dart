import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      destinations: [
        NavigationDestination(
          icon: Semantics(identifier: 'tab_home', child: const Icon(Icons.home_outlined)),
          selectedIcon: Semantics(identifier: 'tab_home', child: const Icon(Icons.home)),
          label: LocaleKeys.homeTab.tr(context: context),
        ),
        NavigationDestination(
          icon: Semantics(identifier: 'tab_second', child: const Icon(Icons.layers_outlined)),
          selectedIcon: Semantics(identifier: 'tab_second', child: const Icon(Icons.layers)),
          label: LocaleKeys.secondTab.tr(context: context),
        ),
      ],
    ),
  );
}
