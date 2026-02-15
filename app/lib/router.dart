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

final router = GoRouter(
  initialLocation: AppRoutes.home,
  navigatorKey: navigatorKey,
  observers: [routeObserver],
  routes: [
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
                  name: 'machines',
                  builder: (context, state) {
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

                    return MachineListScreen(
                      areaIds: areaIds,
                      roomIds: roomIds,
                      machineIds: machineIds,
                      title: extra?['title'] as String?,
                      count: extra?['count'] as String?,
                      types: types,
                    );
                  },
                ),
                GoRoute(
                  path: '${AppRoutes.machineList}/${AppRoutes.machineDetail}',
                  name: 'machineDetail',
                  builder: (context, state) {
                    final machineId = state.pathParameters['machineId']!;
                    Map<String, dynamic>? extra =
                        state.extra as Map<String, dynamic>?;
                    return MachineDetailScreen(
                      key: ValueKey('machine_$machineId'),
                      machineId: machineId,
                      initialAction:
                          extra?['initialAction'] as InitialPageAction? ??
                          InitialPageAction.none,
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
              builder: (context, state) => MyMachinesScreen(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => PreferencesScreen(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.scanQr,
              builder: (context, state) => MobileScannerSimple(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
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

  static const String settings = '/settings';

  // // Helper methods for navigation
  // static String buildMachineListRoute({
  //   List<String>? roomIds,
  //   List<String>? areaIds,
  //   List<String>? machineIds,
  // }) {
  //   final uri = Uri(
  //     path: machineList,
  //     queryParameters: {
  //       if (roomIds != null && roomIds.isNotEmpty) 'roomIds[]': roomIds,
  //       if (areaIds != null && areaIds.isNotEmpty) 'areaIds[]': areaIds,
  //       if (machineIds != null && machineIds.isNotEmpty)
  //         'machineIds[]': machineIds,
  //     },
  //   );
  //   return uri.toString();
  // }

  static String buildMachineDetailRoute(String machineId) {
    return machineDetail.replaceFirst(':machineId', machineId);
  }
}
