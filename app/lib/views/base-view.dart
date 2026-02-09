import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/asset-export.dart';

class BaseView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const BaseView({super.key, required this.navigationShell});

  void _goBranch(int index) {
    print('Navigating to branch index: $index');
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;
    final isOnScanPage = currentLocation == '/scan-qr';

    return Scaffold(
      body: navigationShell,
      floatingActionButton: isOnScanPage
          ? null
          : FloatingActionButton(
              onPressed: () {
                context.push('/scan-qr');
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.qr_code_scanner,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(color: Theme.of(context).colorScheme.primary);
            }
            return TextStyle(color: Theme.of(context).colorScheme.tertiary);
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          indicatorColor: Colors.transparent,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          onDestinationSelected: _goBranch,
          destinations: [
            _menuItem(
              context,
              index: 0,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.home,
              label: 'Home',
            ),
            _menuItem(
              context,
              index: 1,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.local_laundry_service,
              label: 'My Machines',
            ),
            // _menuItem(
            //   context,
            //   index: 2,
            //   currentIndex: navigationShell.currentIndex,
            //   icon: Icons.settings,
            //   label: 'Settings',
            // ),
          ],
        ),
      ),
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
