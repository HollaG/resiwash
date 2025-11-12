import 'package:flutter/material.dart';
import 'package:resiwash/core/injections/room/room_service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/firebase_notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';

class SubscriptionIndicator extends StatefulWidget {
  final String machineId;

  const SubscriptionIndicator({Key? key, required this.machineId})
    : super(key: key);

  @override
  _SubscriptionIndicatorState createState() => _SubscriptionIndicatorState();
}

class _SubscriptionIndicatorState extends State<SubscriptionIndicator> {
  int isSubscribed = 2; // loading state, 0 = not subscribed, 1 = subscribed

  @override
  void initState() {
    super.initState();
    // Initialize subscription status here, possibly from shared preferences or an API
    // For demonstration, we'll set it to not subscribed after a delay
    // initialize the subscription status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sharedPref = sl<SharedPreferencesService>();

      bool subscribed = sharedPref.isSubscribedToMachine(widget.machineId);

      if (mounted) {
        setState(() {
          isSubscribed = subscribed ? 1 : 0;
        });
      }
    });
  }

  Future<void> subscribe() async {
    setState(() {
      isSubscribed = 2;
    });
    try {
      String topicName = await sl<FirebaseNotificationService>()
          .subscribeToMachine(widget.machineId);

      appLog.d("Subscribed to topic: $topicName");

      if (mounted) {
        setState(() {
          isSubscribed = 1;
        });

        // notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Notifications for this machine enabled.")),
        );
      }
    } catch (e) {
      appLog.e("Error subscribing to machine: $e");
      if (mounted) {
        setState(() {
          isSubscribed = 0;
        });
      }
    }
  }

  Future<void> unsubscribe() async {
    setState(() {
      isSubscribed = 2;
    });
    try {
      String topicName = await sl<FirebaseNotificationService>()
          .unsubscribeFromMachine(widget.machineId);
      appLog.d("Unsubscribed from topic: $topicName");

      if (mounted) {
        setState(() {
          isSubscribed = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Notifications for this machine disabled.")),
        );
      }
    } catch (e) {
      appLog.e("Error unsubscribing from machine: $e");
      if (mounted) {
        setState(() {
          isSubscribed = 1;
        });
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Coming soon!")),
        // );
        if (isSubscribed == 1) {
          unsubscribe();
        } else {
          subscribe();
        }
      },
      icon: Icon(
        isSubscribed == 1
            ? Icons.notifications_active
            : Icons.notifications_off,
      ),
    );
  }
}
