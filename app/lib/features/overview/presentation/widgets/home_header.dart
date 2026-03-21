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
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/trackers/tracker_mini_alt.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/trackers/tracker_mini_container.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';
import 'package:resiwash/router.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  const HomeHeader({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OverviewCubit, OverviewState>(
      builder: (context, state) {
        // Calculate counts based on state
        int washerCount = 0;
        int totalWashers = 0;
        int dryerCount = 0;
        int totalDryers = 0;
        bool isLoading = true;

        if (state is OverviewLoaded) {
          isLoading = false;
          Map<CountKey, int> washerInfo = state.getTypeCount(
            MachineType.washer,
          );
          washerCount = washerInfo[CountKey.available] ?? 0;
          totalWashers = washerInfo[CountKey.total] ?? 0;

          Map<CountKey, int> dryerInfo = state.getTypeCount(MachineType.dryer);
          dryerCount = dryerInfo[CountKey.available] ?? 0;
          totalDryers = dryerInfo[CountKey.total] ?? 0;
        }

        final loadedLocations = sl<SharedPreferencesService>()
            .getSavedLocations();

        int numberOfRooms = loadedLocations.getAllRoomIds().length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(36.0, 12, 36, 48),
          color: Theme.of(context).colorScheme.primary,
          child: SafeArea(
            child: Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      "Welcome${numberOfRooms > 0 ? " back" : ""}!",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ],
                ),
                // BlocBuilder<ClaimCubit, ClaimState>(
                //   builder: (context, state) {
                //     if (state is ClaimLoaded) {
                //       final claimedMetaList = state.claimedMachineMetadata;
                //       final claimedMachineList = state.claimedMachines ?? [];

                //       final validMetaList = claimedMetaList
                //           .where(
                //             (meta) => claimedMachineList.any(
                //               (machine) => machine.machineId == meta.machineId,
                //             ),
                //           )
                //           .toList();

                //       if (validMetaList.isEmpty) {
                //         return const SizedBox.shrink();
                //       }

                //       return Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         spacing: 8,
                //         children: [
                //           for (var meta in validMetaList)
                //             TrackerMiniAlt(
                //               machine: claimedMachineList.firstWhere(
                //                 (machine) =>
                //                     machine.machineId == meta.machineId,
                //               ),
                //               claimedMetadata: meta,
                //             ),
                //         ],
                //       );
                //     }

                //     return SizedBox.shrink();
                //   },
                // ),

                // AnimatedSize(
                //   duration: const Duration(milliseconds: 300),
                //   curve: Curves.easeInOut,
                //   child: Builder(
                //     builder: (context) {
                //       if ((numberOfRooms == 0 ||
                //           totalDryers + totalWashers == 0)) {
                //         return Row();
                //       } else {
                //         return Row(
                //           spacing: 12,
                //           children: [
                //             // TODO: hide if no machine of type
                //             if (totalDryers > 0)
                //               Expanded(
                //                 child: HomeMainCard(
                //                   leading: AssetIcons.dryerIcon(context),
                //                   title: "Dryers",
                //                   count: isLoading
                //                       ? "Loading..."
                //                       : "$dryerCount/$totalDryers",
                //                   actionText: "View",
                //                   onAction: isLoading
                //                       ? () {}
                //                       : () {
                //                           context.pushNamed(
                //                             'machines',
                //                             queryParameters: {
                //                               'types[]': [
                //                                 MachineType.dryer.name,
                //                               ],
                //                               'roomIds[]': loadedLocations
                //                                   .getAllRoomIds(),
                //                             },
                //                             extra: {
                //                               'title': "Dryers",
                //                               'count': totalDryers.toString(),
                //                             },
                //                           );
                //                         },
                //                 ),
                //               ),
                //             if (totalWashers > 0)
                //               Expanded(
                //                 child: HomeMainCard(
                //                   leading: AssetIcons.washerIcon(context),
                //                   title: "Washers",
                //                   count: isLoading
                //                       ? "Loading..."
                //                       : "$washerCount/$totalWashers",
                //                   actionText: "View",
                //                   onAction: isLoading
                //                       ? () {}
                //                       : () {
                //                           context.pushNamed(
                //                             'machines',
                //                             queryParameters: {
                //                               'types[]': [
                //                                 MachineType.washer.name,
                //                               ],
                //                               'roomIds[]': loadedLocations
                //                                   .getAllRoomIds(),
                //                             },
                //                             extra: {
                //                               'title': "Washers",
                //                               'count': totalWashers.toString(),
                //                             },
                //                           );
                //                         },
                //                 ),
                //               ),
                //           ],
                //         );
                //       }
                //     },
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}
