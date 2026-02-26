import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/injections/area/area_service_locator.dart';
import 'package:resiwash/core/services/live_notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/subscription_utils.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_state.dart'
    as sub_state;
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart'
    as claim_state;
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

class _MachineRowState extends State<MachineRow>
    with SingleTickerProviderStateMixin {
  SubscriptionState subscriptionState = SubscriptionState.loading;
  ClaimState claimState = ClaimState.loading;

  int isClaimed =
      2; // 0 = not claimed, 1 = claimed, 2 = loading, 3 = success claiming, 4 = success unclaiming

  late final SlidableController controller = SlidableController(this);

  // Cache cubit references to avoid unsafe context lookups
  late final ClaimCubit _claimCubit;
  late final SubscriptionCubit _subscriptionCubit;

  @override
  void initState() {
    super.initState();
    // Cache cubit references early
    _claimCubit = context.read<ClaimCubit>();
    _subscriptionCubit = context.read<SubscriptionCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check subscription and claim status from the respective cubits
      bool isClaimed = _claimCubit.isMachineClaimed(widget.machine.machineId);
      bool isSubscribedIndividually = _subscriptionCubit.isSubscribedToMachine(
        widget.machine.machineId,
      );

      bool isSubscribedInGroup = _subscriptionCubit.isSubscribedToGroup(
        SubscriptionUtils.getTopicNameForGroup(
          widget.machine.roomId,
          widget.machine.type,
        ),
      );

      setState(() {
        subscriptionState = isSubscribedIndividually || isSubscribedInGroup
            ? SubscriptionState.subscribed
            : SubscriptionState.notSubscribed;
        claimState = isClaimed ? ClaimState.claimed : ClaimState.notClaimed;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<int?> _dialogBuilder(
    BuildContext context,
    MachineEntity machine,
  ) async {
    int selectedCycleTime = 30;

    List<int> cycleTimes = [30, 45, 60];
    if (machine.type == MachineType.washer) {
      cycleTimes = [30, 32, 34];
    }

    int? defaultCycleTime = sl<SharedPreferencesService>()
        .getPreferredCycleTime(machine.type);

    if (defaultCycleTime != null) {
      return defaultCycleTime;
    }

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

  Future<void> closeControllerAfterDelay() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to ClaimCubit for claim state changes
        BlocListener<ClaimCubit, claim_state.ClaimState>(
          listener: (context, state) {
            if (state is claim_state.Claiming &&
                state.operatingMachine.machineId == widget.machine.machineId) {
              // change internal state to loading
              setState(() {
                claimState = ClaimState.loading;
              });
            }

            if ((state is claim_state.Claimed &&
                    state.operatingMachine.machineId ==
                        widget.machine.machineId) ||
                (state is claim_state.Unclaimed &&
                    state.operatingMachine.machineId ==
                        widget.machine.machineId)) {
              // change internal state to success
              setState(() {
                claimState = state is claim_state.Claimed
                    ? ClaimState.successClaiming
                    : ClaimState.successUnclaiming;
              });

              // change back to normal 1s later
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    bool isClaimed = _claimCubit.isMachineClaimed(
                      widget.machine.machineId,
                    );
                    claimState = isClaimed
                        ? ClaimState.claimed
                        : ClaimState.notClaimed;
                  });
                }
              });
            }

            if (state is claim_state.ClaimOperationError &&
                state.operatingMachine.machineId == widget.machine.machineId) {
              // reset to previous state on error
              bool isClaimed = _claimCubit.isMachineClaimed(
                widget.machine.machineId,
              );

              setState(() {
                claimState = isClaimed
                    ? ClaimState.claimed
                    : ClaimState.notClaimed;
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
        ),
        // Listen to SubscriptionCubit for subscription state changes
        BlocListener<SubscriptionCubit, sub_state.SubscriptionState>(
          listener: (context, state) {
            print("debug state is $state in subscription machien row");
            if (state is sub_state.SubscribedToGroup ||
                state is sub_state.UnsubscribedFromGroup) {
              // re-check the subscription status from cubit
              bool isSubscribedIndividually = _subscriptionCubit
                  .isSubscribedToMachine(widget.machine.machineId);
              bool isSubscribedInGroup = _subscriptionCubit.isSubscribedToGroup(
                SubscriptionUtils.getTopicNameForGroup(
                  widget.machine.roomId,
                  widget.machine.type,
                ),
              );
              setState(() {
                subscriptionState =
                    isSubscribedIndividually || isSubscribedInGroup
                    ? SubscriptionState.subscribed
                    : SubscriptionState.notSubscribed;
              });
            }

            // ---- commented: we not doing per-machine subscription for now ----
            // if (state is sub_state.Subscribing &&
            //     state.operatingMachine.machineId == widget.machine.machineId) {
            //   // change internal state to loading
            //   setState(() {
            //     subscriptionState = SubscriptionState.loading;
            //   });
            // }

            // if ((state is sub_state.Subscribed &&
            //         state.operatingMachine.machineId ==
            //             widget.machine.machineId) ||
            //     (state is sub_state.Unsubscribed &&
            //         state.operatingMachine.machineId ==
            //             widget.machine.machineId)) {
            //   // change internal state to success
            //   setState(() {
            //     subscriptionState = state is sub_state.Subscribed
            //         ? SubscriptionState.successSubscribing
            //         : SubscriptionState.successUnsubscribing;
            //   });

            //   // change back to normal 1s later
            //   Future.delayed(const Duration(seconds: 1), () {
            //     if (mounted) {
            //       setState(() {
            //         bool isSubscribed = _subscriptionCubit
            //             .isSubscribedToMachine(widget.machine.machineId);
            //         subscriptionState = isSubscribed
            //             ? SubscriptionState.subscribed
            //             : SubscriptionState.notSubscribed;
            //       });
            //     }
            //   });
            // }

            // if (state is sub_state.SubscriptionOperationError &&
            //     state.operatingMachine.machineId == widget.machine.machineId) {
            //   // reset to previous state on error
            //   bool isSubscribed = _subscriptionCubit.isSubscribedToMachine(
            //     widget.machine.machineId,
            //   );

            //   setState(() {
            //     subscriptionState = isSubscribed
            //         ? SubscriptionState.subscribed
            //         : SubscriptionState.notSubscribed;
            //   });

            //   print('Error subscribing to machine: ${state.message}');
            //   if (!TickerMode.of(context)) return;
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(
            //       content: Text(state.message),
            //       duration: const Duration(seconds: 2),
            //     ),
            //   );
            // }
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final location = MachineDisplayUtils.getLocationLabel(widget.machine);
          final time = MachineDisplayUtils.getStatusLabel(widget.machine);
          // ---- commented: we not doing per-machine subscription for now ----
          // String subscribeText = "";

          // switch (subscriptionState) {
          //   case SubscriptionState.notSubscribed:
          //     subscribeText = "Subscribe";
          //     break;
          //   case SubscriptionState.subscribed:
          //     subscribeText = "Unsubscribe";
          //     break;
          //   case SubscriptionState.loading:
          //     subscribeText = "Loading...";
          //     break;
          //   case SubscriptionState.successSubscribing:
          //     subscribeText = "Subscribed!";
          //     break;
          //   case SubscriptionState.successUnsubscribing:
          //     subscribeText = "Unsubscribed!";
          //     break;
          // }

          // Widget notificationIcon = Icon(
          //   Icons.notification_add,
          //   color: Theme.of(context).colorScheme.secondary,
          // );

          // if (subscriptionState == SubscriptionState.loading) {
          //   notificationIcon = SizedBox(
          //     width: 16,
          //     height: 16,
          //     child: CircularProgressIndicator(
          //       strokeWidth: 2,
          //       color: Theme.of(context).colorScheme.secondary,
          //     ),
          //   );
          // }

          // if (subscriptionState == SubscriptionState.successSubscribing ||
          //     subscriptionState == SubscriptionState.successUnsubscribing) {
          //   // success subscribing
          //   notificationIcon = Icon(
          //     Icons.check,
          //     color: Theme.of(context).colorScheme.secondary,
          //   );
          // }

          String claimText = '';
          switch (claimState) {
            case ClaimState.notClaimed:
              claimText = "Use this machine";
              break;
            case ClaimState.claimed:
              claimText = "Release";
              break;
            case ClaimState.loading:
              claimText = "Loading...";
              break;
            case ClaimState.successClaiming:
              claimText = "Now using!";
              break;
            case ClaimState.successUnclaiming:
              claimText = "Released!";
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

          return Slidable(
            key: Key(widget.machine.machineId),
            enabled: widget.allowSwipe,
            closeOnScroll: true,
            controller: controller,

            // Left swipe action (claim/unclaim)
            startActionPane: widget.allowSwipe
                ? ActionPane(
                    motion: const BehindMotion(),
                    extentRatio: 0.3,
                    dismissible: DismissiblePane(
                      dismissThreshold: 0.4,
                      // never ever dismiss
                      onDismissed: () => {},
                      confirmDismiss: () async {
                        if (claimState == ClaimState.loading) {
                          controller.close();
                          return false;
                        }

                        if (claimState == ClaimState.claimed) {
                          await _claimCubit.unclaimMachine(widget.machine);
                        } else if (claimState == ClaimState.notClaimed) {
                          // Show dialog and get selected cycle time
                          final cycleTime = await _dialogBuilder(
                            context,
                            widget.machine,
                          );

                          // Only claim if user confirmed (didn't cancel)
                          if (cycleTime != null && mounted) {
                            final didClaim = await _claimCubit.claimMachine(
                              widget.machine,
                              cycleTime: cycleTime,
                            );

                            print("debug didClaim is $didClaim");

                            // final completer = Completer<void>();
                            // // Wait for the claim operation to complete before closing the slidable
                            // final subscription = context
                            //     .read<ClaimCubit>()
                            //     .stream
                            //     .where(
                            //       (state) =>
                            //           (state is claim_state.Claimed &&
                            //               state.operatingMachine.machineId ==
                            //                   widget.machine.machineId) ||
                            //           (state is claim_state.Unclaimed &&
                            //               state.operatingMachine.machineId ==
                            //                   widget.machine.machineId) ||
                            //           (state is claim_state.ClaimOperationError &&
                            //               state.operatingMachine.machineId ==
                            //                   widget.machine.machineId),
                            //     )
                            //     .listen((state) {
                            //       if ((state is claim_state.Claimed &&
                            //               state.operatingMachine.machineId ==
                            //                   widget.machine.machineId) ||
                            //           (state is claim_state.Unclaimed &&
                            //               state.operatingMachine.machineId ==
                            //                   widget.machine.machineId)) {
                            //         completer.complete();
                            //       }

                            //       if (state
                            //               is claim_state.ClaimOperationError &&
                            //           state.operatingMachine.machineId ==
                            //               widget.machine.machineId) {
                            //         completer.complete();
                            //       }
                            //     });

                            // redirect to MyMachines page after claiming
                            // completer.future.then((_) {
                            if (mounted && context.mounted && didClaim) {
                              context.goNamed(AppRoutes.myMachinesName);
                            }
                            // });
                          }
                        }
                        closeControllerAfterDelay();
                        return false;
                      },
                    ),
                    children: [
                      CustomSlidableAction(
                        onPressed: (context) async {
                          if (claimState == ClaimState.loading) return;

                          if (claimState == ClaimState.claimed) {
                            await _claimCubit.unclaimMachine(widget.machine);
                          } else if (claimState == ClaimState.notClaimed) {
                            // Show dialog and get selected cycle time
                            final cycleTime = await _dialogBuilder(
                              context,
                              widget.machine,
                            );

                            // Only claim if user confirmed (didn't cancel)
                            if (cycleTime != null && mounted) {
                              await _claimCubit.claimMachine(
                                widget.machine,
                                cycleTime: cycleTime,
                              );
                              // redirect to MyMachines page after claiming
                              if (mounted && context.mounted) {
                                context.goNamed(AppRoutes.myMachinesName);
                              }
                            }
                          }
                        },
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        autoClose: true,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            claimIcon,
                            const SizedBox(height: 4),
                            Text(
                              claimText,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,

            // Right swipe action (subscribe/unsubscribe)
            // endActionPane: widget.allowSwipe
            //     ? ActionPane(
            //         motion: const BehindMotion(),
            //         extentRatio: 0.25,
            //         dismissible: DismissiblePane(
            //           onDismissed: () => {},
            //           dismissThreshold: 0.4,
            //           confirmDismiss: () async {
            //             if (subscriptionState == SubscriptionState.loading) {
            //               controller.close();
            //               return false;
            //             }

            //             final subscriptionCubit = context
            //                 .read<SubscriptionCubit>();

            //             if (subscriptionState == SubscriptionState.subscribed) {
            //               await subscriptionCubit.unsubscribeFromMachine(
            //                 widget.machine,
            //               );
            //             } else if (subscriptionState ==
            //                 SubscriptionState.notSubscribed) {
            //               await subscriptionCubit.subscribeToMachine(
            //                 widget.machine,
            //               );
            //             }
            //             closeControllerAfterDelay();
            //             return false;
            //           },
            //         ),
            //         children: [
            //           CustomSlidableAction(
            //             onPressed: (context) async {
            //               if (subscriptionState == SubscriptionState.loading)
            //                 return;

            //               final subscriptionCubit = context
            //                   .read<SubscriptionCubit>();

            //               if (subscriptionState ==
            //                   SubscriptionState.subscribed) {
            //                 await subscriptionCubit.unsubscribeFromMachine(
            //                   widget.machine,
            //                 );
            //               } else if (subscriptionState ==
            //                   SubscriptionState.notSubscribed) {
            //                 await subscriptionCubit.subscribeToMachine(
            //                   widget.machine,
            //                 );
            //               }
            //             },
            //             backgroundColor: context.accent.colorContainer,
            //             foregroundColor: Theme.of(
            //               context,
            //             ).colorScheme.secondary,
            //             borderRadius: BorderRadius.circular(8),
            //             autoClose: true,
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 notificationIcon,
            //                 const SizedBox(height: 4),
            //                 Text(
            //                   subscribeText,
            //                   style: Theme.of(context).textTheme.labelSmall
            //                       ?.copyWith(
            //                         color: Theme.of(
            //                           context,
            //                         ).colorScheme.secondary,
            //                       ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ],
            //       )
            //     : null,
            child: Container(
              decoration: BoxDecoration(
                // borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                onTap: () {
                  // go to /machines/:id
                  context.pushNamed(
                    AppRoutes.machineDetailName,
                    pathParameters: {'machineId': widget.machine.machineId},
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
        },
      ),
    );
  }
}
