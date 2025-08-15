import 'package:resiwash/main.dart';
import 'package:resiwash/views/base-view.dart';
import 'package:resiwash/views/home/HomePage.dart';
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
              builder: (context, state) => HomePage(),
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

  static const String home = '/';
  static const String myMachines = '/me';
  static const String profile = '/profile';
}
