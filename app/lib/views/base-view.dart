import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/claim_machine_help_info.dart';
import 'package:resiwash/router.dart';

class BaseView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final GoRouterState shellState;
  const BaseView({
    super.key,
    required this.navigationShell,
    required this.shellState,
  });

  void _goBranch(int index) {
    print('Navigating to branch index: $index');
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _onHelpClicked(BuildContext context) {
    ClaimMachineHelpInfo.show(context);
  }

  @override
  Widget build(BuildContext context) {
    // Do NOT show FAB on the scan QR page, since it would be redundant and could cause issues if the user tries to open multiple scan QR pages. Instead, only show the FAB on the Home and My Machines pages.
    final path = shellState.uri.path;

    final isOnScanQrPage = path == AppRoutes.scanQr;
    print(
      "debug currentPage is now $path, isOnScanQrPage: $isOnScanQrPage, currentNavigationIndex is ${navigationShell.currentIndex}",
    );
    return Scaffold(
      body: navigationShell,
      // floatingActionButton: shouldShowFAB
      //     ? FloatingActionButton(
      //         onPressed: () => context.push(AppRoutes.scanQr),
      //         backgroundColor: Theme.of(context).colorScheme.primary,
      //         child: Icon(
      //           Icons.qr_code_scanner,
      //           color: Theme.of(context).colorScheme.onPrimary,
      //         ),
      //       )
      //     : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
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
          labelBehavior: isOnScanQrPage
              ? NavigationDestinationLabelBehavior.alwaysHide
              : NavigationDestinationLabelBehavior.onlyShowSelected,

          // height: 24,
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

            // IMPORTANT: When uncommenting this, make sure to change the goBranch of the FAB
            // _menuItem(
            //   context,
            //   index: 2,
            //   currentIndex: navigationShell.currentIndex,
            //   icon: Icons.settings,
            //   label: 'Settings',
            // ),
            Center(
              child: FloatingActionButton(
                onPressed: () {
                  if (!isOnScanQrPage) {
                    navigationShell.goBranch(
                      2,
                      initialLocation: 2 == navigationShell.currentIndex,
                    );
                  } else {
                    _onHelpClicked(context);
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  isOnScanQrPage ? Icons.help : Icons.qr_code_scanner,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
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
