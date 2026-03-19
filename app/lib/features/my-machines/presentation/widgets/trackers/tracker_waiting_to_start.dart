import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/router.dart';
import 'package:resiwash/theme.dart';

class TrackerWaitingToStart extends StatefulWidget {
  final MachineEntity machine;
  final ClaimedMachineMetadata claimedMetadata;
  final bool showControls;

  const TrackerWaitingToStart({
    super.key,
    required this.machine,
    required this.claimedMetadata,
    required this.showControls,
  });

  @override
  State<TrackerWaitingToStart> createState() => _TrackerWaitingToStartState();
}

class _TrackerWaitingToStartState extends State<TrackerWaitingToStart>
    with SingleTickerProviderStateMixin {
  late final SlidableController controller = SlidableController(this);

  Future<int?> _dialogBuilder(
    BuildContext context,
    MachineEntity machine,
  ) async {
    int selectedCycleTime = widget.claimedMetadata.cycleTime;

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
                              return Theme.of(context).colorScheme.primary;
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
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Confirm'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedCycleTime);
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
  void dispose() {
    controller.close();
    controller.dispose();
    super.dispose();
  }

  Future<void> onUnclaimPress() async {
    controller.openTo(1.0);
    await context.read<ClaimCubit>().unclaimMachine(widget.machine);
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
          onTap: () {
            _dialogBuilder(context, widget.machine).then((newCycleTime) async {
              if (newCycleTime != null) {
                if (mounted && context.mounted) {
                  final didUpdate = await context
                      .read<ClaimCubit>()
                      .updateCycleTime(widget.machine, newCycleTime);
                  if (!mounted || !context.mounted) return;

                  if (!didUpdate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to update cycle time. Please try again.',
                        ),
                      ),
                    );
                  } else {
                    context.read<ClaimCubit>().refreshClaimedMachines();
                  }
                }
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                                '${widget.machine.room?.name} @ ${widget.machine.room?.area?.shortName ?? widget.machine.room?.area?.name}',
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
                const SizedBox(height: 16),
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
                              value: 0,
                              strokeAlign: -1,
                              strokeWidth: 16,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
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
                                color: Theme.of(context).colorScheme.primary,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '0%',
                                style: Theme.of(context).textTheme.headlineSmall
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
                              '${widget.claimedMetadata.cycleTime} minute cycle',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                  ),
                            ),
                          ],
                        ),
                        Text(
                          'Waiting to start...',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox.shrink(),
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
                        onPressed: onUnclaimPress,
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            context.success.color,
                          ),
                        ),
                        child: const Text('I have collected!'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
