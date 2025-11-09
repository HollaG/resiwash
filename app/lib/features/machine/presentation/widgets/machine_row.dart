import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
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
                  await context.read<MyMachinesCubit>().claimMachine(
                    widget.machine,
                  );
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

  // @override
  // Widget build2(BuildContext context) {
  //   // Use the utility function to generate the complete subtitle
  //   final location = MachineDisplayUtils.getLocationLabel(widget.machine);
  //   final time = MachineDisplayUtils.getStatusLabel(widget.machine);

  //   String notificationText = "";
  //   if (isSubscribed == 1) {
  //     notificationText = "Unsubscribe";
  //   } else if (isSubscribed == 0) {
  //     notificationText = "Subscribe";
  //   } else if (isSubscribed == 2) {
  //     notificationText = "Loading...";
  //   } else if (isSubscribed == 3) {
  //     notificationText = "Subscribed!";
  //   } else if (isSubscribed == 4) {
  //     notificationText = "Unsubscribed!";
  //   }

  //   Widget notificationIcon = Icon(
  //     Icons.notification_add,
  //     color: Theme.of(context).colorScheme.secondary,
  //   );

  //   if (isSubscribed == 1) {
  //     notificationIcon = Icon(
  //       Icons.notifications_off,
  //       color: Theme.of(context).colorScheme.secondary,
  //     );
  //   } else if (isSubscribed == 2) {
  //     notificationIcon = SizedBox(
  //       width: 16,
  //       height: 16,
  //       child: CircularProgressIndicator(
  //         strokeWidth: 2,
  //         color: Theme.of(context).colorScheme.secondary,
  //       ),
  //     );
  //   } else if (isSubscribed == 3) {
  //     // success subscribing
  //     notificationIcon = Icon(
  //       Icons.check,
  //       color: Theme.of(context).colorScheme.secondary,
  //     );
  //   } else if (isSubscribed == 4) {
  //     // success unsubscribing
  //     notificationIcon = Icon(
  //       Icons.check,
  //       color: Theme.of(context).colorScheme.secondary,
  //     );
  //   }

  //   String claimText = "";
  //   if (isClaimed == 1) {
  //     claimText = "Unclaim";
  //   } else if (isClaimed == 0) {
  //     claimText = "Claim";
  //   } else if (isClaimed == 2) {
  //     claimText = "Loading...";
  //   } else if (isClaimed == 3) {
  //     claimText = "Claimed!";
  //   } else if (isClaimed == 4) {
  //     claimText = "Unclaimed!";
  //   }

  //   return Dismissible(
  //     // subscribe
  //     direction: widget.allowSwipe
  //         ? DismissDirection.horizontal
  //         : DismissDirection.none,

  //     // claim
  //     background: Container(
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(8),
  //         color: Theme.of(context).colorScheme.primaryContainer,
  //       ),
  //       // color: Theme.of(context).colorScheme.secondaryContainer,
  //       alignment: Alignment.centerRight,
  //       padding: const EdgeInsets.symmetric(horizontal: 20),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.end,
  //         spacing: 8,
  //         children: [
  //           Text(
  //             notificationText,
  //             style: Theme.of(context).textTheme.labelSmall?.copyWith(
  //               color: Theme.of(context).colorScheme.onPrimaryContainer,
  //             ),
  //           ),
  //           notificationIcon,
  //         ],
  //       ),
  //     ),

  //     // sub/unsub
  //     secondaryBackground: Container(
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(8),
  //         color: context.accent.colorContainer,
  //       ),
  //       alignment: Alignment.centerRight,
  //       padding: const EdgeInsets.symmetric(horizontal: 20),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.end,
  //         spacing: 8,
  //         children: [
  //           Text(
  //             notificationText,
  //             style: Theme.of(context).textTheme.labelSmall?.copyWith(
  //               color: Theme.of(context).colorScheme.secondary,
  //             ),
  //           ),
  //           notificationIcon,
  //         ],
  //       ),
  //     ),
  //     key: Key(widget.machine.machineId),

  //     confirmDismiss: (direction) async {
  //       // wait 1s
  //       if (direction == DismissDirection.endToStart) {
  //         if (isSubscribed == 1) {
  //           // unsubscribe
  //           await unsubscribe();
  //         } else if (isSubscribed == 0) {
  //           // subscribe
  //           await subscribe();
  //         }
  //         // SUBSCRIBE
  //       } else if (direction == DismissDirection.startToEnd) {
  //         // UNSUBSCRIBE
  //         return null;
  //       }
  //     }, // don't dismiss
  //     child: Container(
  //       decoration: BoxDecoration(
  //         // borderRadius: BorderRadius.circular(8),
  //         color: Theme.of(context).colorScheme.surface,
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: ListTile(
  //         onTap: () {
  //           // go to /machines/:id
  //           context
  //               .push(
  //                 Uri(
  //                   path: AppRoutes.buildMachineDetailRoute(
  //                     widget.machine.machineId,
  //                   ),
  //                 ).toString(),
  //                 extra: {'machine': widget.machine},
  //               )
  //               .then((_) => {_checkSubscriptionStatus()});
  //         },
  //         title: Column(
  //           children: [
  //             Row(
  //               crossAxisAlignment: CrossAxisAlignment.center,
  //               spacing: 8,
  //               children: [
  //                 Row(
  //                   spacing: 4,
  //                   children: [
  //                     if (isSubscribed == 1)
  //                       Icon(
  //                         Icons.notifications,
  //                         size: 14,
  //                         // color: Theme.of(
  //                         //   context,
  //                         // ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
  //                       ),
  //                     Text(
  //                       widget.machine.name,
  //                       style: Theme.of(context).textTheme.labelMedium,
  //                     ),
  //                   ],
  //                 ),
  //                 Expanded(
  //                   child: Text(
  //                     "@ $location",
  //                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //                       color: Theme.of(
  //                         context,
  //                       ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
  //                     ),
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                     softWrap: false,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //         subtitle: Column(
  //           spacing: 2,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               time,
  //               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                 color: MachineStatusIndicator.getTextColor(
  //                   context,
  //                   widget.machine.currentStatus,
  //                 ),
  //               ),
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //               softWrap: false,
  //             ),
  //           ],
  //         ),
  //         trailing: (widget.showIcon)
  //             ? (widget.machine.type == MachineType.washer
  //                   ? AssetIcons.washerIcon(context)
  //                   : AssetIcons.dryerIcon(context))
  //             : SizedBox.shrink(),
  //         leading: MachineStatusIndicator(status: widget.machine.currentStatus),
  //       ),
  //     ),
  //   );
  // }
}
