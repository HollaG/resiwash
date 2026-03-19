import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/router.dart';
import 'package:resiwash/theme.dart';

class TrackerMini extends StatefulWidget {
  final MachineEntity machine;
  final ClaimedMachineMetadata claimedMetadata;
  const TrackerMini({
    super.key,
    required this.machine,
    required this.claimedMetadata,
  });

  @override
  State<TrackerMini> createState() => _TrackerMiniState();
}

class _TrackerMiniState extends State<TrackerMini>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Timer _refreshTimer;

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
    // _fastRefreshTimer.cancel();

    super.dispose();
  }

  String shortenName(String name) {
    final normalizedName = name.trim();

    // Accept values like W01, W1, D3, Dryer D04, or just D04 and extract digits.
    final prefixedMatch = RegExp(
      r'[WD]\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(normalizedName);
    final numberMatch =
        prefixedMatch ?? RegExp(r'(\d+)').firstMatch(normalizedName);

    if (numberMatch == null) {
      return normalizedName;
    }

    final number = numberMatch.group(1)!;

    final typePrefix = switch (widget.machine.type) {
      MachineType.washer => 'W',
      MachineType.dryer => 'D',
      _ =>
        widget.machine.type.name.isNotEmpty
            ? widget.machine.type.name[0].toUpperCase()
            : '',
    };

    return '$typePrefix$number';
  }

  Widget _calculateTimeLeftText(BuildContext context) {
    if (MachineDisplayUtils.isAvailableLike(widget.machine.currentStatus)) {
      // cancel the refresh timer
      _refreshTimer.cancel();

      // if fastRefreshTimer is active, cancel it
      // if (_fastRefreshTimer.isActive) {
      //   _fastRefreshTimer.cancel();
      // }
      return Text("Done");
    }
    final cycleTime = widget.claimedMetadata.cycleTime;

    if (cycleTime == null) {
      return Text("?");
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
        // if (!_fastRefreshTimer.isActive) {
        //   _refreshTimer.cancel();
        //   _fastRefreshTimer = Timer.periodic(const Duration(seconds: 10), (
        //     timer,
        //   ) {
        //     print(
        //       "debug refreshing machine data for ${widget.machine.machineId}",
        //     );
        //     context.read<ClaimCubit>().refreshClaimedMachines();
        //   });
        // }

        return Text("Almost...", style: Theme.of(context).textTheme.labelSmall);
      }

      return Text(
        '$minutes:${seconds.toString().padLeft(2, '0')}',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
      );
    }

    return Text("?");
  }

  @override
  Widget build(BuildContext context) {
    if (MachineDisplayUtils.isAvailableLike(widget.machine.currentStatus)) {
      return Center(
        child: InkWell(
          splashColor: Theme.of(context).colorScheme.primary.withAlpha(50),
          onTap: () {
            // navigate to the machine
            final machineId = widget.machine.machineId;
            context.goNamed(
              AppRoutes.machineDetailName,
              pathParameters: {'machineId': widget.machine.machineId},
              extra: {'machine': widget.machine},
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.success.color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: context.success.colorContainer.withAlpha(100),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                MachineStatusIndicator(status: widget.machine.currentStatus),
                Text(
                  shortenName(widget.machine.name),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Done"),
                // Text("Time remaining: ${_formatDuration(_getRemainingTime())}"),
              ],
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: InkWell(
          splashColor: Theme.of(context).colorScheme.primary.withAlpha(50),
          onTap: () {
            // navigate to the machine
            final machineId = widget.machine.machineId;
            context.goNamed(
              AppRoutes.machineDetailName,
              pathParameters: {'machineId': widget.machine.machineId},
              extra: {'machine': widget.machine},
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.accent.colorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,

              spacing: 4,
              children: [
                MachineStatusIndicator(status: widget.machine.currentStatus),
                Text(
                  shortenName(widget.machine.name),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                _calculateTimeLeftText(context),
              ],
            ),
          ),
        ),
      );
    }
  }
}
