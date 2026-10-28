import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
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
