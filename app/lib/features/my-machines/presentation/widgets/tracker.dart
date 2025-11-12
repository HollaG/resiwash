import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_cubit.dart';
import 'package:resiwash/router.dart';
import 'package:resiwash/theme.dart';
import 'package:go_router/go_router.dart';

class Tracker extends StatefulWidget {
  final MachineEntity machine;
  final ClaimedMachineMetadata claimedMetadata;

  const Tracker({
    super.key,
    required this.machine,
    required this.claimedMetadata,
  });

  @override
  State<Tracker> createState() => _TrackerState();
}

class _TrackerState extends State<Tracker> {
  late Timer _timer;
  late Timer _refreshTimer;
  // late Duration _timeSe;

  @override
  void initState() {
    super.initState();

    // Start a periodic timer that updates every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print("debug Tracker timer tick");
      setState(() {});
    });

    // Optionally, you can have another timer to refresh data from server every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      print("debug refreshing machine data for ${widget.machine.machineId}");
      // Here you would typically call a method to refresh the machine data
      // For example:
      // context.read<MachineCubit>().refreshMachineData(widget.machine.machineId);
      context.read<MyMachinesCubit>().refreshClaimedMachines();
    });
  }

  // Cancel the timer to prevent memory leaks
  @override
  void dispose() {
    _timer.cancel();
    _refreshTimer.cancel();
    super.dispose();
  }

  Widget _calculateTimeLeftText(BuildContext context) {
    if (widget.machine.currentStatus == MachineStatus.available) {
      // cancel the refresh timer
      _refreshTimer.cancel();
      return Text("Completed");
    }
    final cycleTime = widget.claimedMetadata.cycleTime;

    if (cycleTime == null) {
      return Text("Unknown");
    }

    final lastAvailableTime = widget.machine.lastAvailableTime;
    print("debug lastAvailableTime $lastAvailableTime");
    if (lastAvailableTime != null) {
      // calculate time left in X min X sec
      final totalCycleDuration = Duration(minutes: cycleTime);
      final timeSinceAvailable = DateTime.now().difference(lastAvailableTime);
      final timeLeft = totalCycleDuration - timeSinceAvailable;

      final minutes = timeLeft.inMinutes;
      final seconds = timeLeft.inSeconds % 60;

      // Additional: if time left is negative, show "almost done"
      if (timeLeft.isNegative) {
        // change the refresh timer to refresh every 10 seconds instead
        _refreshTimer.cancel();
        _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          print(
            "debug refreshing machine data for ${widget.machine.machineId}",
          );
          context.read<MyMachinesCubit>().refreshClaimedMachines();
        });

        return Text(
          "Almost done...",
          style: Theme.of(context).textTheme.headlineSmall,
        );
      }

      return RichText(
        text: TextSpan(
          text: "",
          style: Theme.of(context).textTheme.headlineSmall,
          children: [
            TextSpan(
              text: "$minutes min $seconds sec ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: "left",
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      );
    }

    return Text("Unknown");
  }

  Widget _calculateTimeSinceText(BuildContext context) {
    if (widget.machine.currentStatus == MachineStatus.available) {
      final lastAvailableTime = widget.machine.lastAvailableTime;
      if (lastAvailableTime != null) {
        final timeSinceAvailable = DateTime.now().difference(lastAvailableTime);

        final minutes = timeSinceAvailable.inMinutes;
        final seconds = timeSinceAvailable.inSeconds % 60;

        return Text(
          "$minutes min $seconds sec ago",
          style: Theme.of(context).textTheme.bodySmall,
        );
      }

      return Text("Unknown");
    } else if (widget.machine.currentStatus == MachineStatus.inUse ||
        widget.machine.currentStatus == MachineStatus.finishing) {
      final lastAvailableTime = widget.machine.lastAvailableTime;
      if (lastAvailableTime != null) {
        final timeSinceAvailable = DateTime.now().difference(lastAvailableTime);

        final minutes = timeSinceAvailable.inMinutes;
        final seconds = timeSinceAvailable.inSeconds % 60;

        return Text(
          "Started $minutes min $seconds sec ago",
          style: Theme.of(context).textTheme.bodySmall,
        );
      }

      // fallback to using the time since machine was in use
      final lastChangeTime = widget.machine.lastChangeTime;
      if (lastChangeTime != null) {
        final timeSinceInUse = DateTime.now().difference(lastChangeTime);

        final minutes = timeSinceInUse.inMinutes;
        final seconds = timeSinceInUse.inSeconds % 60;

        return Text(
          "Started $minutes min $seconds sec ago",
          style: Theme.of(context).textTheme.bodySmall,
        );
      }
    }

    return Text("Unknown");
  }

  int _calculatePercentDone(BuildContext context) {
    if (widget.machine.currentStatus == MachineStatus.available) {
      return 100;
    }
    final cycleTime = widget.claimedMetadata.cycleTime;
    if (cycleTime == null) {
      return 0;
    }
    final lastAvailableTime = widget.machine.lastAvailableTime;
    if (lastAvailableTime != null) {
      final totalCycleDuration = Duration(minutes: cycleTime);
      final timeSinceAvailable = DateTime.now().difference(lastAvailableTime);
      final percentDone =
          (timeSinceAvailable.inSeconds / totalCycleDuration.inSeconds * 100)
              .clamp(0, 100)
              .toInt();
      print("debug calculated lastAvailableTime percentDone $percentDone");
      return percentDone;
    }

    // fallback to using lastChangeTime
    final lastChangeTime = widget.machine.lastChangeTime;
    if (lastChangeTime != null) {
      final totalCycleDuration = Duration(minutes: cycleTime);
      final timeSinceChange = DateTime.now().difference(lastChangeTime);
      final percentDone =
          (timeSinceChange.inSeconds / totalCycleDuration.inSeconds * 100)
              .clamp(0, 100)
              .toInt();
      print("debug calculated lastChangeTime percentDone $percentDone");
      return percentDone;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.accent.colorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // top widget
          InkWell(
            onTap: () {
              // Navigate to machine details page
              context.push(
                Uri(
                  path: AppRoutes.buildMachineDetailRoute(
                    widget.machine.machineId,
                  ),
                ).toString(),
                extra: {'machine': widget.machine},
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                spacing: 12,
                children: [
                  MachineStatusIndicator(
                    status: widget.machine.currentStatus,
                    size: BoxSize.large,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.machine.name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          "${widget.machine.room?.name} @ ${widget.machine.room?.area?.shortName}",
                        ),
                      ],
                    ),
                  ),
                  widget.machine.type == MachineType.washer
                      ? AssetIcons.washerIcon(context)
                      : AssetIcons.dryerIcon(context),
                ],
              ),
            ),
          ),

          // todo
          SizedBox(height: 16),
          Row(
            spacing: 24,
            children: [
              Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: _calculatePercentDone(context) / 100,
                        strokeAlign: -1,
                        strokeWidth: 16,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MachineStatusIndicator.getConnectorColor(
                            context,
                            widget.machine.currentStatus,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: MachineStatusIndicator.getIndicatorColor(
                            context,
                            widget.machine.currentStatus,
                          ),
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                    ),
                  ),

                  SizedBox(
                    width: 96,
                    height: 96,

                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96.0,
                    height: 96.0,

                    child: Center(
                      child: Container(
                        width: 96 - 16 * 2 - 2,
                        height: 96 - 16 * 2 - 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              // color: Colors.black.withOpacity(0.25),
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${_calculatePercentDone(context)}%",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  // cycle indicator
                  Row(
                    spacing: 4,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      Text(
                        "${widget.claimedMetadata.cycleTime} minute cycle",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),

                  // time left
                  _calculateTimeLeftText(context),

                  // time since started
                  _calculateTimeSinceText(context),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
