import 'package:resiwash/features/overview/presentation/screens/home_screen.dart';
import 'package:resiwash/features/machine/presentation/screens/machine_list_screen.dart';
import 'package:resiwash/main.dart';
import 'package:resiwash/views/base-view.dart';

import 'package:resiwash/views/my-machines/myMachinesPage.dart';
import 'package:resiwash/views/profile/profilePage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: AppRoutes.home,

  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BaseView(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => HomeScreen(),
            ),
            GoRoute(
              path: AppRoutes.machineList,
              name: 'machines', // Add name for easier navigation
              builder: (context, state) {
                print(
                  'Machine route hit with URI: ${state.uri}',
                ); // Debug print
                final roomIds = state.uri.queryParametersAll['roomIds[]'] ?? [];
                final areaIds = state.uri.queryParametersAll['areaIds[]'] ?? [];
                final machineIds =
                    state.uri.queryParametersAll['machineIds[]'] ?? [];

                print('Parsed roomIds: $roomIds'); // Debug print

                Map<String, dynamic> extra =
                    state.extra as Map<String, dynamic>;

                return MachineListScreen(
                  areaIds: areaIds,
                  roomIds: roomIds,
                  machineIds: machineIds,
                  title: extra['title'] as String?,
                  count: extra['count'] as String?,
                );
              },
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myMachines,
              builder: (context, state) => MyMachinesPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

final _routerKey = GlobalKey<NavigatorState>();

class AppRoutes {
  AppRoutes._();

  // -- routes for Home page -- //
  static const String home = '/';
  static const String machineList = '/machines';

  static const String myMachines = '/me';
  static const String profile = '/profile';

  // Helper methods for navigation
  static String buildMachineListRoute({
    List<String>? roomIds,
    List<String>? areaIds,
    List<String>? machineIds,
  }) {
    final uri = Uri(
      path: machineList,
      queryParameters: {
        if (roomIds != null && roomIds.isNotEmpty) 'roomIds[]': roomIds,
        if (areaIds != null && areaIds.isNotEmpty) 'areaIds[]': areaIds,
        if (machineIds != null && machineIds.isNotEmpty)
          'machineIds[]': machineIds,
      },
    );
    return uri.toString();
  }
}
