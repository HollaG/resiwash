import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:resiwash/core/injections/room/room_service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/services/local_notification_service.dart';
import 'package:resiwash/core/utils/subscription_utils.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';

enum CustomFirebaseMessageChannel { claimed, subscribed, poke, subscribedGroup }

CustomFirebaseMessageChannel getChannelFromString(String channelString) {
  return CustomFirebaseMessageChannel.values.firstWhere(
    (e) => e.name == channelString,
    orElse: () => throw Exception("Unknown channel: $channelString"),
  );
}

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<String> _getPermission() async {
    await _firebaseMessaging.requestPermission();
    return await _firebaseMessaging.getToken() ?? "";
  }

  /// When the app is opened from a FIREBASE notification, NOT a local notification
  void _handleMessageWhenOpenedFromNotification(RemoteMessage message) {
    // Handle the message and navigate to specific screen if needed
    appLog.i(
      "[FirebaseNotificationService] App opened from notification: $message",
    );
    // You can add navigation logic here based on message data

    // _handleMessageWhenInApp(message);
  }

  void _handleMessageWhenInApp(RemoteMessage message) {
    // Handle the message when the app is in the foreground
    appLog.i(
      "[FirebaseNotificationService] Message received in foreground: $message",
    );
    // You can show a local notification here if needed

    // RemoteNotification notification = message.notification;
    // AndroidNotification android = message.notification?.android;

    // display the message contents in appLog
    appLog.i(
      "[FirebaseNotificationService] Notification: ${message.data} of type ${message.data['channel']}",
    );

    if (message.data.containsKey("channel")) {
      // Parse the string value to the enum
      final channelString = message.data["channel"] as String;
      final channel = CustomFirebaseMessageChannel.values.firstWhere(
        (e) => e.name == channelString,
        orElse: () => throw Exception("Unknown channel: $channelString"),
      );
      appLog.i("[FirebaseNotificationService] channel: $channel");
      // Handle different channels if needed

      /// Subscribed: show notification directly as set from BE
      /// Claimed:
      switch (channel) {
        case CustomFirebaseMessageChannel.subscribed:
          // Handle subscribed channel
          sl<LocalNotificationService>().showSubscribed(message);

          break;

        case CustomFirebaseMessageChannel.claimed:
          // TODO: IMPLEMENT
          //
          // data: {
          //       machineId: machine.machineId.toString(),
          //       machineName: machine.name,
          //       machineRoomName: machine.room.name,
          //       machineAreaShortName: machine.room.area.shortName,
          //       machineCurrentStatus: machine.currentStatus,
          //       machinePreviousStatus: machine.previousStatus,

          //       channel: "claimed",
          //     },

          // need to update the claimed notification
          // as well as force a refresh of the claimed machines in app
          // get the metadata
          // final machineId = message.data['machineId'] as String;
          // final metadata = sl<SharedPreferencesService>().getClaimedMachineMetadata(machineId);
          // if (metadata == null) {
          //   appLog.w(
          //     "[FirebaseNotificationService] No claimed metadata found for machineId: $machineId",
          //   );
          //   return;
          // }
          // sl<LocalNotificationService>().showClaimedNotification(message);
          break;
        case CustomFirebaseMessageChannel.poke:
          // Handle poke channel
          sl<LocalNotificationService>().showPoke(message);
          break;
        default:
          appLog.w("[FirebaseNotificationService] Unhandled channel: $channel");
      }
    }
  }

  Future<void> initialize() async {
    try {
      // request for permission on app launch
      await _getPermission();

      // check if this app was opened from a notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageWhenOpenedFromNotification(initialMessage);
      }

      // Also handle any interaction when the app is in the background via a
      // Stream listener
      FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageWhenOpenedFromNotification,
      );

      // When app is minimized but not closed
      FirebaseMessaging.onMessage.listen(_handleMessageWhenInApp);

      // NOTE: Background message handler must be registered in main.dart as a top-level function
      // Do not register it here to avoid null check errors

      // IOS: display on foreground
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true, // Required to display a heads up notification
            badge: true,
            sound: true,
          );

      // Android: display on foreground
      // note: android is handled in android/app/src/main/AndroidManifest.xml:
      // https://firebase.flutter.dev/docs/messaging/notifications/

      // print the token for debug
      final fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $fcmToken');
    } catch (e) {
      print("Error initializing permissions: $e");
    }
  }

  // TODO: check how to guarantee non-null token
  Future<String> getFcmToken() async {
    return await _firebaseMessaging.getToken() ?? "";
  }

  Future<String> subscribeToMachine(String machineId) async {
    try {
      String topic = SubscriptionUtils.getTopicNameForMachine(machineId);
      await _subscribeToTopic(topic);
      sl<SharedPreferencesService>().subscribeToMachine(machineId);

      appLog.i("Subscribed to machine $machineId");

      return topic;
    } catch (e) {
      appLog.e("Error subscribing to machine $machineId: $e");
      rethrow;
    }
  }

  Future<String> unsubscribeFromMachine(String machineId) async {
    try {
      String topic = SubscriptionUtils.getTopicNameForMachine(machineId);
      await _unsubscribeFromTopic(topic);
      sl<SharedPreferencesService>().unsubscribeFromMachine(machineId);

      appLog.i("Unsubscribed from machine $machineId");

      return topic;
    } catch (e) {
      appLog.e("Error unsubscribing from machine $machineId: $e");
      rethrow;
    }
  }

  Future<String> subscribeToGroup(String topic) async {
    try {
      await _subscribeToTopic(topic);
      sl<SharedPreferencesService>().subscribeToGroups({topic});

      appLog.i("Subscribed to group $topic");

      return topic;
    } catch (e) {
      appLog.e("Error subscribing to group $topic: $e");
      rethrow;
    }
  }

  Future<String> unsubscribeFromGroup(String topic) async {
    try {
      await _unsubscribeFromTopic(topic);
      sl<SharedPreferencesService>().unsubscribeFromGroups({topic});

      appLog.i("Unsubscribed from group $topic");

      return topic;
    } catch (e) {
      appLog.e("Error unsubscribing from group $topic: $e");
      rethrow;
    }
  }

  Future<void> _subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
