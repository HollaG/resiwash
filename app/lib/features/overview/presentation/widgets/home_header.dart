import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resiwash/core/injections/area/area_service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/common/views/homeMainCard.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';
import 'package:resiwash/router.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  const HomeHeader({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(36.0, 48, 36, 48),
        color: Theme.of(context).colorScheme.primary,

        child: SafeArea(
          child: Column(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    "Welcome back!",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      // fontWeight is already bold from theme
                    ),
                  ),
                ],
              ),

              BlocBuilder<OverviewCubit, OverviewState>(
                builder: (context, state) {
                  if (state is OverviewLoaded) {
                    // Calculate counts based on actual data
                    Map<CountKey, int> washerInfo = state.getTypeCount(
                      MachineType.washer,
                    );
                    int washerCount = washerInfo[CountKey.available] ?? 0;
                    int totalWashers = washerInfo[CountKey.total] ?? 0;

                    Map<CountKey, int> dryerInfo = state.getTypeCount(
                      MachineType.dryer,
                    );
                    int dryerCount = dryerInfo[CountKey.available] ?? 0;
                    int totalDryers = dryerInfo[CountKey.total] ?? 0;

                    final loadedLocations = sl<SharedPreferencesService>()
                        .getSavedLocations();

                    return Row(
                      children: [
                        Expanded(
                          child: HomeMainCard(
                            leading: AssetIcons.dryerIcon(context),
                            title: "Dryers",
                            count: "$dryerCount/$totalDryers",

                            actionText: "View",
                            onAction: () {
                              // Navigate to the washer list page
                              context.push(
                                Uri(
                                  path: AppRoutes.machineList,
                                  queryParameters: {
                                    'types[]': [MachineType.dryer.name],
                                    'roomIds[]': loadedLocations
                                        .getAllRoomIds(),
                                  },
                                ).toString(),
                                extra: {
                                  'title': "Dryers",
                                  'count': totalDryers.toString(),
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: HomeMainCard(
                            leading: AssetIcons.washerIcon(context),
                            title: "Washers",
                            count: "$washerCount/$totalWashers",

                            actionText: "View",
                            onAction: () {
                              // Navigate to the washer list page
                              context.push(
                                Uri(
                                  path: AppRoutes.machineList,
                                  queryParameters: {
                                    'types[]': [MachineType.washer.name],
                                    'roomIds[]': loadedLocations
                                        .getAllRoomIds(),
                                  },
                                ).toString(),
                                extra: {
                                  'title': "Washers",
                                  'count': totalWashers.toString(),
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: HomeMainCard(
                          leading: AssetIcons.washerIcon(context),
                          title: "Washers",
                          count: "Loading...",

                          actionText: "View",
                          onAction: () {},
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: HomeMainCard(
                          leading: AssetIcons.dryerIcon(context),
                          title: "Dryers",
                          count: "Loading...",

                          actionText: "View",
                          onAction: () {},
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
