import 'package:flutter/material.dart';
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

class _MachineRowState extends State<MachineRow> {
  // 0 = not subscribed, 1 = subscribed, 2 = loading, 3 = success subscribing, 4 = success unsubscribing
  int isSubscribed = 2;

  int isClaimed =
      2; // 0 = not claimed, 1 = claimed, 2 = loading, 3 = success claiming, 4 = success unclaiming

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionStatus(); // visible in UI
      _checkClaimStatus(); // not visible in UI
    });
  }

  void _checkSubscriptionStatus() {
    final sharedPref = sl<SharedPreferencesService>();

    bool subscribed = sharedPref.isSubscribedToMachine(
      widget.machine.machineId,
    );

    setState(() {
      isSubscribed = subscribed ? 1 : 0;
    });
  }

  void _checkClaimStatus() {
    final sharedPref = sl<SharedPreferencesService>();

    bool claimed = sharedPref.isMachineClaimed(widget.machine.machineId);

    setState(() {
      isClaimed = claimed ? 1 : 0;
    });
  }

  Future<void> subscribe() async {
    setState(() {
      isSubscribed = 2;
    });
    try {
      String topicName = await sl<NotificationService>().subscribeToMachine(
        widget.machine.machineId,
      );

      appLog.d("Subscribed to topic: $topicName");

      if (mounted) {
        setState(() {
          isSubscribed = 3;
        });
      }

      // set a timer to reset the state back to unsubscribed after 1s
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            isSubscribed = 1;
          });
        }
      });

      // notification
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Notifications for this machine enabled.")),
      // );
    } catch (e) {
      appLog.e("Error subscribing to machine: $e");
      if (mounted) {
        setState(() {
          isSubscribed = 0;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("There was an error subscribing to this machine."),
        ),
      );
    }
  }

  Future<void> unsubscribe() async {
    setState(() {
      isSubscribed = 2;
    });
    try {
      String topicName = await sl<NotificationService>().unsubscribeFromMachine(
        widget.machine.machineId,
      );
      appLog.d("Unsubscribed from topic: $topicName");

      if (mounted) {
        setState(() {
          isSubscribed = 4;
        });
      }

      // set a timer to reset the state back to unsubscribed after 1s
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            isSubscribed = 0;
          });
        }
      });
    } catch (e) {
      appLog.e("Error unsubscribing from machine: $e");
      if (mounted) {
        setState(() {
          isSubscribed = 1;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("There was an error unsubscribing from this machine."),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the utility function to generate the complete subtitle
    final location = MachineDisplayUtils.getLocationLabel(widget.machine);
    final time = MachineDisplayUtils.getStatusLabel(widget.machine);

    String notificationText = "";
    if (isSubscribed == 1) {
      notificationText = "Unsubscribe";
    } else if (isSubscribed == 0) {
      notificationText = "Subscribe";
    } else if (isSubscribed == 2) {
      notificationText = "Loading...";
    } else if (isSubscribed == 3) {
      notificationText = "Subscribed!";
    } else if (isSubscribed == 4) {
      notificationText = "Unsubscribed!";
    }

    Widget notificationIcon = Icon(
      Icons.notification_add,
      color: Theme.of(context).colorScheme.secondary,
    );

    if (isSubscribed == 1) {
      notificationIcon = Icon(
        Icons.notifications_off,
        color: Theme.of(context).colorScheme.secondary,
      );
    } else if (isSubscribed == 2) {
      notificationIcon = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.secondary,
        ),
      );
    } else if (isSubscribed == 3) {
      // success subscribing
      notificationIcon = Icon(
        Icons.check,
        color: Theme.of(context).colorScheme.secondary,
      );
    } else if (isSubscribed == 4) {
      // success unsubscribing
      notificationIcon = Icon(
        Icons.check,
        color: Theme.of(context).colorScheme.secondary,
      );
    }

    String claimText = "";
    if (isClaimed == 1) {
      claimText = "Unclaim";
    } else if (isClaimed == 0) {
      claimText = "Claim";
    } else if (isClaimed == 2) {
      claimText = "Loading...";
    } else if (isClaimed == 3) {
      claimText = "Claimed!";
    } else if (isClaimed == 4) {
      claimText = "Unclaimed!";
    }

    return Dismissible(
      // subscribe
      direction: widget.allowSwipe
          ? DismissDirection.horizontal
          : DismissDirection.none,

      // claim
      background: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        // color: Theme.of(context).colorScheme.secondaryContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            Text(
              notificationText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            notificationIcon,
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
              notificationText,
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
          if (isSubscribed == 1) {
            // unsubscribe
            await unsubscribe();
          } else if (isSubscribed == 0) {
            // subscribe
            await subscribe();
          }
          // SUBSCRIBE
        } else if (direction == DismissDirection.startToEnd) {
          // UNSUBSCRIBE
          return null;
        }
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
            context
                .push(
                  Uri(
                    path: AppRoutes.buildMachineDetailRoute(
                      widget.machine.machineId,
                    ),
                  ).toString(),
                  extra: {'machine': widget.machine},
                )
                .then((_) => {_checkSubscriptionStatus()});
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
                      if (isSubscribed == 1)
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
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
          leading: MachineStatusIndicator(status: widget.machine.currentStatus),
        ),
      ),
    );
  }
}
