import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/injections/room/room_service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/router.dart';
import 'package:resiwash/theme.dart';
import 'package:go_router/go_router.dart';

class Tracker extends StatefulWidget {
  final MachineEntity machine;
  final ClaimedMachineMetadata claimedMetadata;
  final bool showControls;

  const Tracker({
    super.key,
    required this.machine,
    required this.claimedMetadata,
    required this.showControls,
  });

  @override
  State<Tracker> createState() => _TrackerState();
}

class _TrackerState extends State<Tracker> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Timer _refreshTimer;
  Timer _fastRefreshTimer = Timer(const Duration(seconds: 0), () {});
  int selectedCycleTime = 30;
  late final SlidableController controller = SlidableController(this);
  // late Duration _timeSe;

  @override
  void initState() {
    super.initState();

    // Start a periodic timer that updates every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });

    // Optionally, you can have another timer to refresh data from server every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Here you would typically call a method to refresh the machine data
      context.read<ClaimCubit>().refreshClaimedMachines();
    });
  }

  // Cancel the timer to prevent memory leaks
  @override
  void dispose() {
    _timer.cancel();
    _refreshTimer.cancel();
    _fastRefreshTimer.cancel();
    controller.dispose();
    super.dispose();
  }

  Widget _calculateTimeLeftText(BuildContext context) {
    if (MachineDisplayUtils.isAvailableLike(widget.machine.currentStatus)) {
      // cancel the refresh timer
      _refreshTimer.cancel();

      // if fastRefreshTimer is active, cancel it
      if (_fastRefreshTimer.isActive) {
        _fastRefreshTimer.cancel();
      }
      return Text("Completed");
    }
    final cycleTime = widget.claimedMetadata.cycleTime;

    if (cycleTime == null) {
      return Text("Unknown");
    }

    final lastAvailableTime = widget.machine.lastAvailableTime;
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
        // if fastRefreshTimer is not set
        if (!_fastRefreshTimer.isActive) {
          _refreshTimer.cancel();
          _fastRefreshTimer = Timer.periodic(const Duration(seconds: 10), (
            timer,
          ) {
            print(
              "debug refreshing machine data for ${widget.machine.machineId}",
            );
            context.read<ClaimCubit>().refreshClaimedMachines();
          });
        }

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
    if (MachineDisplayUtils.isAvailableLike(widget.machine.currentStatus)) {
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
    if (MachineDisplayUtils.isAvailableLike(widget.machine.currentStatus)) {
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
      return percentDone;
    }
    return -1;
  }

  Future<void> onUnclaimPress() async {
    controller.openTo(1.0);
    // controller.
    await context.read<ClaimCubit>().unclaimMachine(widget.machine);
  }

  Future<int?> _dialogBuilder(
    BuildContext context,
    MachineEntity machine,
  ) async {
    int selectedCycleTime =
        widget.claimedMetadata.cycleTime ?? 30; // default to 30 if null

    List<int> cycleTimes = [30, 45, 60];
    if (machine.type == MachineType.washer) {
      cycleTimes = [30, 32, 34];
    }

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.all(12),
              title: Text(
                'Update cycle time (now ${widget.claimedMetadata.cycleTime} min)',
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 12.0,
                children: [
                  Text(
                    'Please choose your cycle time for the machine you are using.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Center(
                    child: SegmentedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return (Theme.of(context).colorScheme.primary);
                            }
                            return Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).colorScheme.onPrimary;
                            }
                            return Theme.of(context).colorScheme.onSurface;
                          },
                        ),
                      ),
                      segments: <ButtonSegment<int>>[
                        for (int cycleTime in cycleTimes)
                          ButtonSegment<int>(
                            value: cycleTime,
                            label: Text('${cycleTime}m'),
                          ),
                      ],
                      selected: <int>{selectedCycleTime},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          selectedCycleTime = newSelection.first;
                        });
                      },
                    ),
                  ),

                  // Padding(
                  //   padding: const EdgeInsets.fromLTRB(24.0, 0, 24, 0),
                  //   child: Row(
                  //     spacing: 20,
                  //     children: [
                  //       Expanded(child: Divider(), flex: 1),
                  //       Text("or"),
                  //       Expanded(child: Divider(), flex: 1),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Returns null
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Confirm'),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(selectedCycleTime); // Return selected time
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: Key(widget.machine.machineId),
      controller: controller,
      enabled: true,
      closeOnScroll: false,
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.3,
        dismissible: DismissiblePane(
          dismissThreshold: 0.7,
          onDismissed: () {},
          confirmDismiss: () async {
            context.read<ClaimCubit>().unclaimMachine(widget.machine);
            return false;
          },
        ),
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              context.read<ClaimCubit>().unclaimMachine(widget.machine);
            },
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            borderRadius: BorderRadius.circular(8),
            autoClose: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 4),
                Text(
                  'Release',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.4,
        dismissible: DismissiblePane(
          onDismissed: () {},
          dismissThreshold: 0.7,
          confirmDismiss: () async {
            context.read<ClaimCubit>().unclaimMachine(widget.machine);
            return false;
          },
        ),
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              context.read<ClaimCubit>().unclaimMachine(widget.machine);
            },
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            borderRadius: BorderRadius.circular(8),
            autoClose: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 4),
                Text(
                  'Release',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Card(
        elevation: 3,
        color: context.accent.colorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(0),
        child: InkWell(
          onTap:
              MachineDisplayUtils.isAvailableLike(widget.machine.currentStatus)
              ? null
              : () {
                  _dialogBuilder(context, widget.machine).then((
                    newCycleTime,
                  ) async {
                    if (newCycleTime != null) {
                      // Update the cycle time in the cubit
                      if (mounted && context.mounted) {
                        final didUpdate = await context
                            .read<ClaimCubit>()
                            .updateCycleTime(widget.machine, newCycleTime);
                        if (!mounted || !context.mounted) return;
                        if (!didUpdate) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Failed to update cycle time. Please try again.",
                              ),
                            ),
                          );
                        } else {
                          // refresh the page
                          if (mounted && context.mounted) {
                            context.read<ClaimCubit>().refreshClaimedMachines();
                          }
                        }
                      }
                    }
                  });
                },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // top widget
                  InkWell(
                    onTap: () {
                      context.goNamed(
                        AppRoutes.machineDetailName,
                        pathParameters: {'machineId': widget.machine.machineId},
                        extra: {'machine': widget.machine},
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
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
                                  "${widget.machine.room?.name} @ ${widget.machine.room?.area?.shortName ?? widget.machine.room?.area?.name}",
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
                                  color:
                                      MachineStatusIndicator.getIndicatorColor(
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${_calculatePercentDone(context)}%",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                    ),
                              ),
                            ],
                          ),

                          _calculateTimeLeftText(context),
                          _calculateTimeSinceText(context),
                        ],
                      ),
                    ],
                  ),

                  Visibility(
                    visible: widget.showControls,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            onUnclaimPress();
                          },
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all<Color>(
                              context.success.color,
                            ),
                          ),
                          child: const Text("I have collected!"),
                        ),
                        // TextButton.icon(
                        //   onPressed: () {
                        //     // int initialCycleTime =
                        //     //     widget.claimedMetadata.cycleTime ??
                        //     //     30; // default to 30 if null
                        //     // _dialogBuilder(context, initialCycleTime).then((
                        //     //   newTime,
                        //     // ) {
                        //     //   if (newTime != null) {
                        //     //     // Update the cycle time in the cubit
                        //     //     if (mounted) {
                        //     //       context.read<ClaimCubit>().updateCycleTime(
                        //     //         widget.machine,
                        //     //         newTime,
                        //     //       );
                        //     //     }
                        //     //   }
                        //     // });
                        //   },
                        //   label: Text("Edit cycle time"),
                        //   icon: Icon(Icons.edit),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
