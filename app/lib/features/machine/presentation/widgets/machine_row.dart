import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_state.dart';
import 'package:resiwash/router.dart';
import 'package:resiwash/theme.dart';

/**
 * UI design:
 * 
 * User can swipe left to subscribe to notifications.
 * Swiping left again after subscribing will show a pop up on how long the cycle is.
 * Swiping right will cancel the subscription.
 */

class MachineRow extends StatefulWidget {
  final MachineEntity machine;
  final bool showIcon;
  final bool allowSwipe;

  const MachineRow({
    super.key,
    required this.machine,
    this.showIcon = true,
    this.allowSwipe = true,
  });

  @override
  State<MachineRow> createState() => _MachineRowState();
}

enum SubscriptionState {
  notSubscribed,
  subscribed,
  loading,
  successSubscribing,
  successUnsubscribing,
}

enum ClaimState {
  notClaimed,
  claimed,
  loading,
  successClaiming,
  successUnclaiming,
}

class _MachineRowState extends State<MachineRow> {
  SubscriptionState subscriptionState = SubscriptionState.loading;
  ClaimState claimState = ClaimState.loading;

  int isClaimed =
      2; // 0 = not claimed, 1 = claimed, 2 = loading, 3 = success claiming, 4 = success unclaiming

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Now, we do this separately, because we don't want to listen to MyMachinesCubit load success.
      bool isClaimed = context.read<MyMachinesCubit>().isMachineClaimed(
        widget.machine.machineId,
      );
      bool isSubscribed = context.read<MyMachinesCubit>().isSubscribedToMachine(
        widget.machine.machineId,
      );

      setState(() {
        subscriptionState = isSubscribed
            ? SubscriptionState.subscribed
            : SubscriptionState.notSubscribed;
        claimState = isClaimed ? ClaimState.claimed : ClaimState.notClaimed;
      });
    });
  }

  Future<int?> _dialogBuilder(BuildContext context) {
    int selectedCycleTime = 30;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.all(12),
              title: const Text('Set cycle time'),
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
                      segments: const <ButtonSegment<int>>[
                        ButtonSegment<int>(value: 30, label: Text('30m')),
                        ButtonSegment<int>(value: 45, label: Text('45m')),
                        ButtonSegment<int>(value: 60, label: Text('60m')),
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
    return BlocConsumer<MyMachinesCubit, MyMachinesState>(
      /// NOTE: Since the MyMachinesCubit is provided higher up in the tree,
      ///       other MachineRows will receive state updates from this MachineRow, and vice versa.
      ///       We can listen to `state.operatingMachine.machineId` to filter out irrelevant updates.
      listener: (context, state) {
        if (state is MyMachinesLoaded) {}

        if (state is MyMachinesClaiming &&
            state.operatingMachine.machineId == widget.machine.machineId) {
          // change internal state to loading
          setState(() {
            claimState = ClaimState.loading;
          });
        }

        if ((state is MyMachinesClaimed &&
                state.operatingMachine.machineId == widget.machine.machineId) ||
            (state is MyMachinesUnclaimed &&
                state.operatingMachine.machineId == widget.machine.machineId)) {
          // change internal state to success
          setState(() {
            claimState = state is MyMachinesClaimed
                ? ClaimState.successClaiming
                : ClaimState.successUnclaiming;
          });

          // change back to normal 1s later
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                bool isClaimed = context
                    .read<MyMachinesCubit>()
                    .isMachineClaimed(widget.machine.machineId);
                claimState = isClaimed
                    ? ClaimState.claimed
                    : ClaimState.notClaimed;
              });
            }
          });
        }

        if (state is MyMachinesSubscribing &&
            state.operatingMachine.machineId == widget.machine.machineId) {
          // change internal state to loading
          setState(() {
            subscriptionState = SubscriptionState.loading;
          });
        }

        if (state is MyMachinesSubscribed &&
                state.operatingMachine.machineId == widget.machine.machineId ||
            (state is MyMachinesUnsubscribed &&
                state.operatingMachine.machineId == widget.machine.machineId)) {
          // change internal state to success
          setState(() {
            subscriptionState = state is MyMachinesSubscribed
                ? SubscriptionState.successSubscribing
                : SubscriptionState.successUnsubscribing;
          });

          // change back to normal 1s later
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                bool isSubscribed = context
                    .read<MyMachinesCubit>()
                    .isSubscribedToMachine(widget.machine.machineId);
                subscriptionState = isSubscribed
                    ? SubscriptionState.subscribed
                    : SubscriptionState.notSubscribed;
              });
            }
          });
        }

        if (state is MyMachinesErrorClaiming &&
            state.operatingMachine.machineId == widget.machine.machineId) {
          // reset to previous state on error
          bool isClaimed = context.read<MyMachinesCubit>().isMachineClaimed(
            widget.machine.machineId,
          );

          setState(() {
            claimState = isClaimed ? ClaimState.claimed : ClaimState.notClaimed;
          });

          print('Error claiming machine: ${state.message}');
          // show error message in snackbar only if this route is currently active
          // because MachineRow is used in two StatefulShellBranches that are both kept in memory.
          if (!TickerMode.of(context)) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is MyMachinesLoaded) {
          final location = MachineDisplayUtils.getLocationLabel(widget.machine);
          final time = MachineDisplayUtils.getStatusLabel(widget.machine);
          String subscribeText = "";

          switch (subscriptionState) {
            case SubscriptionState.notSubscribed:
              subscribeText = "Subscribe";
              break;
            case SubscriptionState.subscribed:
              subscribeText = "Unsubscribe";
              break;
            case SubscriptionState.loading:
              subscribeText = "Loading...";
              break;
            case SubscriptionState.successSubscribing:
              subscribeText = "Subscribed!";
              break;
            case SubscriptionState.successUnsubscribing:
              subscribeText = "Unsubscribed!";
              break;
          }

          Widget notificationIcon = Icon(
            Icons.notification_add,
            color: Theme.of(context).colorScheme.secondary,
          );

          if (subscriptionState == SubscriptionState.loading) {
            notificationIcon = SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.secondary,
              ),
            );
          }

          if (subscriptionState == SubscriptionState.successSubscribing ||
              subscriptionState == SubscriptionState.successUnsubscribing) {
            // success subscribing
            notificationIcon = Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.secondary,
            );
          }

          String claimText = '';
          switch (claimState) {
            case ClaimState.notClaimed:
              claimText = "Claim";
              break;
            case ClaimState.claimed:
              claimText = "Unclaim";
              break;
            case ClaimState.loading:
              claimText = "Loading...";
              break;
            case ClaimState.successClaiming:
              claimText = "Claimed!";
              break;
            case ClaimState.successUnclaiming:
              claimText = "Unclaimed!";
              break;
          }

          Widget claimIcon = claimState == ClaimState.notClaimed
              ? Icon(
                  Icons.person_add_alt_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )
              : Icon(
                  Icons.person_off_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                );

          if (claimState == ClaimState.loading) {
            claimIcon = SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            );
          }

          if (claimState == ClaimState.successClaiming ||
              claimState == ClaimState.successUnclaiming) {
            // success claiming
            claimIcon = Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }

          return Dismissible(
            // subscribe
            direction: widget.allowSwipe
                ? DismissDirection.horizontal
                : DismissDirection.none,

            onDismissed: (direction) {},
            // claim
            background: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              // color: Theme.of(context).colorScheme.secondaryContainer,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    claimText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  claimIcon,
                ],
              ),
            ),

            // sub/unsub
            secondaryBackground: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: context.accent.colorContainer,
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    subscribeText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  notificationIcon,
                ],
              ),
            ),
            key: Key(widget.machine.machineId),

            confirmDismiss: (direction) async {
              // wait 1s
              if (direction == DismissDirection.endToStart) {
                if (subscriptionState == SubscriptionState.subscribed) {
                  await context.read<MyMachinesCubit>().unsubscribeFromMachine(
                    widget.machine,
                  );
                } else if (subscriptionState ==
                    SubscriptionState.notSubscribed) {
                  await context.read<MyMachinesCubit>().subscribeToMachine(
                    widget.machine,
                  );
                } else {
                  return null;
                }
              } else if (direction == DismissDirection.startToEnd) {
                if (claimState == ClaimState.claimed) {
                  await context.read<MyMachinesCubit>().unclaimMachine(
                    widget.machine,
                  );
                } else if (claimState == ClaimState.notClaimed) {
                  // Show dialog and get selected cycle time
                  final cycleTime = await _dialogBuilder(context);

                  // Only claim if user confirmed (didn't cancel)
                  if (cycleTime != null && mounted) {
                    await context.read<MyMachinesCubit>().claimMachine(
                      widget.machine,
                      cycleTime: cycleTime,
                    );
                  }
                } else {
                  return null;
                }
              }

              return null;
            }, // don't dismiss
            child: Container(
              decoration: BoxDecoration(
                // borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                onTap: () {
                  // go to /machines/:id
                  context.push(
                    Uri(
                      path: AppRoutes.buildMachineDetailRoute(
                        widget.machine.machineId,
                      ),
                    ).toString(),
                    extra: {'machine': widget.machine},
                  );
                  // .then((_) => {_checkSubscriptionStatus()});
                },
                title: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Row(
                          spacing: 4,
                          children: [
                            if (subscriptionState ==
                                SubscriptionState.subscribed)
                              Icon(
                                Icons.notifications,
                                size: 14,
                                // color: Theme.of(
                                //   context,
                                // ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              ),
                            Text(
                              widget.machine.name,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                        Expanded(
                          child: Text(
                            "@ $location",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                subtitle: Column(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MachineStatusIndicator.getTextColor(
                          context,
                          widget.machine.currentStatus,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                ),
                trailing: (widget.showIcon)
                    ? (widget.machine.type == MachineType.washer
                          ? AssetIcons.washerIcon(context)
                          : AssetIcons.dryerIcon(context))
                    : SizedBox.shrink(),
                leading: MachineStatusIndicator(
                  status: widget.machine.currentStatus,
                ),
              ),
            ),
          );
        }

        return CircularProgressIndicator();
      },
    );
  }
}
