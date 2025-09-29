import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BaseView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const BaseView({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      // bottomNavigationBar: NavigationBarTheme(
      //   data: NavigationBarThemeData(
      //     labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
      //       if (states.contains(WidgetState.selected)) {
      //         return TextStyle(color: Theme.of(context).colorScheme.primary);
      //       }
      //       return TextStyle(color: Theme.of(context).colorScheme.tertiary);
      //     }),
      //   ),
      //   child: NavigationBar(
      //     selectedIndex: navigationShell.currentIndex,
      //     indicatorColor: Colors.transparent,
      //     onDestinationSelected: _goBranch,
      //     destinations: [
      //       _menuItem(
      //         context,
      //         index: 0,
      //         currentIndex: navigationShell.currentIndex,
      //         icon: Icons.menu,
      //         label: 'Home',
      //       ),
      //       _menuItem(
      //         context,
      //         index: 1,
      //         currentIndex: navigationShell.currentIndex,
      //         icon: Icons.bookmark,
      //         label: 'My Machines',
      //       ),
      //       _menuItem(
      //         context,
      //         index: 2,
      //         currentIndex: navigationShell.currentIndex,
      //         icon: Icons.person,
      //         label: 'Profile',
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required String label,
    required IconData icon,
  }) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color: currentIndex == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.tertiary,
      ),
      label: label,
    );
  }
}
