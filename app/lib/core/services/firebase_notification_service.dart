import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:resiwash/core/injections/room/room_service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/services/local_notification_service.dart';
import 'package:resiwash/core/utils/datetime_utils.dart';
import 'package:resiwash/core/utils/snackbar_helper.dart';
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

  Future<bool> hasNotificationPermission() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String> getPermission() async {
    await _firebaseMessaging.requestPermission();

    if (Platform.isIOS) {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      int retries = 0;
      while (apnsToken == null && retries < 5) {
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await _firebaseMessaging.getAPNSToken();
        retries++;
      }
      if (apnsToken == null) {
        appLog.e(
          "[FirebaseNotificationService] APNS token not received after 5 seconds",
        );
        return "";
      }
    }

    try {
      return await _firebaseMessaging.getToken() ?? "";
    } catch (e) {
      appLog.e("[FirebaseNotificationService] Error getting FCM token: $e");
      return "";
    }
  }

  /// When the app is opened from a FIREBASE notification, NOT a local notification
  void _handleMessageWhenOpenedFromNotification(RemoteMessage message) {
    // Handle the message and navigate to specific screen if needed
    appLog.i(
      "[FirebaseNotificationService] App opened from notification: $message",
    );
    // You can add navigation logic here based on message data

    // handleRemoteMessage(message);
  }

  void handleRemoteMessage(
    RemoteMessage message, {
    bool fromBackground = false,
  }) {
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
          if (!fromBackground) {
            // only show local notification if the message is received in foreground
            sl<LocalNotificationService>().showSubscribed(message);
          }
          break;

        case CustomFirebaseMessageChannel.claimed:
          final currentMachineStatus = MachineStatus.values.firstWhere(
            (e) => e.value == message.data['machineCurrentStatus'],
            orElse: () => MachineStatus.unknown,
          );

          final secondsTillCompletion = int.tryParse(
            message.data['secondsTillCompletion'] ?? '',
          );

          var title =
              message.data['title'] as String? ??
              'Your claimed machine has an update';

          var body =
              message.data['body'] as String? ??
              'Tap to view details about your machine progress.';

          final showTimer =
              (message.data['forceShowTimer'] as String?) == 'true';

          final machineId = message.data['machineId'] as String;
          final machineName = message.data['machineName'] as String;
          final machineRoomName = message.data['machineRoomName'] as String;

          print("debug raw machineType is ${message.data['machineType']}");
          final machineType = MachineType.values.firstWhere(
            (e) => e.name == message.data['machineType'],
            orElse: () => MachineType.unknown,
          );

          // if secondsTillCompletion is not null, calculate expected end time and replace "[[ expectedEndTime ]]" in both title and body
          if (secondsTillCompletion != null) {
            final expectedEndTime = DateTime.now().add(
              Duration(seconds: secondsTillCompletion),
            );

            final expectedEndTimeString = DateTimeUtils.formatReadableTime(
              expectedEndTime,
            );

            if (title.contains('[[ expectedEndTime ]]')) {
              title = title.replaceAll(
                '[[ expectedEndTime ]]',
                expectedEndTimeString,
              );
            }

            if (body.contains('[[ expectedEndTime ]]')) {
              body = body.replaceAll(
                '[[ expectedEndTime ]]',
                expectedEndTimeString,
              );
            }
          }

          if (showTimer) {
            sl<LocalNotificationService>().showNotificationAndStartTimer(
              title,
              body,
              secondsTillCompletion ?? 0,
              machineId,
              machineName,
              machineRoomName,
              machineType,
            );
            return;
          }

          switch (currentMachineStatus) {
            case MachineStatus.available:
              sl<LocalNotificationService>()
                  .showClaimedMachineNowAvailableNotification(title, body);
              break;
            case MachineStatus.inUse:
              sl<LocalNotificationService>().showNotificationAndStartTimer(
                title,
                body,
                secondsTillCompletion ?? 0,
                machineId,
                machineName,
                machineRoomName,
                machineType,
              );
              break;
            case MachineStatus.finishing:
              sl<LocalNotificationService>()
                  .showClaimedMachineFinishingNotification(
                    title,
                    body,
                    secondsTillCompletion ?? 0,
                  );
              break;
            default:
              appLog.w(
                "[FirebaseNotificationService] Unknown machine status for claimed notification: $currentMachineStatus",
              );
            // show claimed notification
            // sl<LocalNotificationService>().showClaimedNotification(message);
          }

          // TODO: IMPLEMENT
          //
          // data: {title, body, secondsTillCompletion }

          // final machineId = message.data['machineId'] as String;
          // final machineName = message.data['machineName'] as String;
          // final machineRoomName = message.data['machineRoomName'] as String;
          // final machineAreaShortName =
          //     message.data['machineAreaShortName'] as String;
          // final machineCurrentStatus = MachineStatus.values.firstWhere(
          //   (e) => e.value == message.data['machineCurrentStatus'],
          //   orElse: () => MachineStatus.unknown,
          // );
          // final machinePreviousStatus = MachineStatus.values.firstWhere(
          //   (e) => e.value == message.data['machinePreviousStatus'],
          //   orElse: () => MachineStatus.unknown,
          // );

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
          if (!fromBackground) {
            // only show local notification if the message is received in foreground
            sl<LocalNotificationService>().showPoke(message);
          }
          break;
        default:
          appLog.w("[FirebaseNotificationService] Unhandled channel: $channel");
      }
    }
  }

  Future<void> initialize() async {
    try {
      // request for permission on app launch
      await getPermission();

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

      // When app is in foreground
      FirebaseMessaging.onMessage.listen(handleRemoteMessage);

      // NOTE: Background message handler must be registered in main.dart as a top-level function
      // Do not register it here to avoid null check errors

      // IOS: do NOT display on foreground (handled by LocalNotificationService)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false, // Required to display a heads up notification
            badge: true,
            sound: true,
          );

      // print the token for debug
      try {
        if (Platform.isIOS) {
          // wait briefly just in case, though _getPermission handles the main wait
          await Future.delayed(const Duration(seconds: 2));
        }
        final fcmToken = await _firebaseMessaging.getToken();
        print('FCM Token: $fcmToken');
      } catch (e) {
        print("Could not get FCM token during initialization: $e");
      }
    } catch (e) {
      print("Error initializing permissions: $e");
    }
  }

  // TODO: check how to guarantee non-null token
  Future<String> getFcmToken() async {
    if (Platform.isIOS) {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();

      if (apnsToken == null) {
        appLog.e("APNS token not available!");

        // TODO: we will probably display this in a notifications settings page to be developed
        SnackbarHelper.showWarning(
          message:
              "Notifications are disabled - enable them to get progress update notifications.",
        );
        return "";
      }
    }
    try {
      return await _firebaseMessaging.getToken() ?? "";
    } catch (e) {
      appLog.e("Error getting FCM token: $e");
      return "";
    }
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
