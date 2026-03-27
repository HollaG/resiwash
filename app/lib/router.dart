import 'package:resiwash/features/machine/presentation/screens/machine_detail_screen.dart';
import 'package:resiwash/features/my-machines/presentation/screens/scan_qr_screen.dart';
import 'package:resiwash/features/overview/presentation/screens/home_screen.dart';
import 'package:resiwash/features/machine/presentation/screens/machine_list_screen.dart';
import 'package:resiwash/features/preferences/presentation/screens/preferences_screen.dart';
import 'package:resiwash/main.dart';
import 'package:resiwash/views/base-view.dart';

import 'package:resiwash/views/my-machines/oldmyMachinesPage.dart';
import 'package:resiwash/features/my-machines/presentation/screens/my_machines_screen.dart';
import 'package:resiwash/views/profile/profilePage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

CustomTransitionPage<T> _buildSlidePage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

final router = GoRouter(
  initialLocation: AppRoutes.home,
  navigatorKey: navigatorKey,
  observers: [routeObserver],
  routes: [
    // Deep link handler for NFC tags
    GoRoute(
      path: '/manual',
      redirect: (context, state) {
        final machineId = state.uri.queryParameters['machineId'];
        if (machineId != null) {
          return '/machines/$machineId?claim=true';
        }
        return '/'; // Fallback to home if no machineId
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BaseView(navigationShell: navigationShell, shellState: state);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => HomeScreen(),
              routes: [
                GoRoute(
                  path: AppRoutes.machineList,
                  name: AppRoutes.machineListName,
                  pageBuilder: (context, state) {
                    print('Machine route hit with URI: ${state.uri}');
                    final roomIds =
                        state.uri.queryParametersAll['roomIds[]'] ?? [];
                    final areaIds =
                        state.uri.queryParametersAll['areaIds[]'] ?? [];
                    final machineIds =
                        state.uri.queryParametersAll['machineIds[]'] ?? [];
                    final types = state.uri.queryParametersAll['types[]'] ?? [];

                    Map<String, dynamic>? extra =
                        state.extra as Map<String, dynamic>?;

                    return _buildSlidePage(
                      state: state,
                      child: MachineListScreen(
                        areaIds: areaIds,
                        roomIds: roomIds,
                        machineIds: machineIds,
                        title: extra?['title'] as String?,
                        count: extra?['count'] as String?,
                        types: types,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: '${AppRoutes.machineList}/${AppRoutes.machineDetail}',
                  name: AppRoutes.machineDetailName,
                  pageBuilder: (context, state) {
                    final machineId = state.pathParameters['machineId']!;
                    Map<String, dynamic>? extra =
                        state.extra as Map<String, dynamic>?;

                    // Check if this is from a deep link (has 'claim' query param)
                    final shouldClaim =
                        state.uri.queryParameters['claim'] == 'true' ||
                        extra?['initialAction'] == InitialPageAction.claim;

                    String key = 'machine_$machineId';
                    if (shouldClaim) {
                      // NEVER reuse the same key for a machine detail page if we're gonna apply the claim action
                      // make sure it always rebuilds
                      key += '_claim_${DateTime.now().millisecondsSinceEpoch}';
                    }
                    print(
                      "debug route hit machine detail key: $key, shouldClaim: $shouldClaim, extra: $extra, ${extra?['initialAction']}, ${InitialPageAction.claim}",
                    );

                    return _buildSlidePage(
                      state: state,
                      child: MachineDetailScreen(
                        key: ValueKey(key),
                        machineId: machineId,
                        initialAction: shouldClaim
                            ? InitialPageAction.claim
                            : (extra?['initialAction'] as InitialPageAction? ??
                                  InitialPageAction.none),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myMachines,
              name: AppRoutes.myMachinesName,
              builder: (context, state) => MyMachinesScreen(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: AppRoutes.settingsName,
              builder: (context, state) => PreferencesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.scanQr,
              name: AppRoutes.scanQrName,
              builder: (context, state) => MobileScannerSimple(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              name: AppRoutes.profileName,
              builder: (context, state) => ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppRoutes {
  AppRoutes._();

  // -- routes for Home page -- //
  static const String home = '/';
  static const String machineList = 'machines'; // nested under home
  static const String machineDetail = ':machineId'; // nested under machineList

  static const String myMachines = '/me';
  static const String profile = '/profile';
  static const String scanQr = '/scan-qr';

  static const int scanQrBranchIndex = 3;

  static const String settings = '/settings';

  // -- route names -- //
  static const String machineListName = 'machines';
  static const String machineDetailName = 'machineDetail';
  static const String myMachinesName = 'myMachines';
  static const String scanQrName = 'scanQr';
  static const String profileName = 'profile';
  static const String settingsName = 'settings';

  static String buildMachineDetailRoute(String machineId) {
    return machineDetail.replaceFirst(':machineId', machineId);
  }
}
