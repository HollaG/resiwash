import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:resiwash/core/injections/room/room_service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/subscription_utils.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // unique ID
    try {
      await _firebaseMessaging.requestPermission();

      final fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $fcmToken');

      // when app is minimized
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      });

      // when app is open
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Message clicked! ${message.messageId}');
      });

      // NOTE: Background message handler must be registered in main.dart as a top-level function
      // Do not register it here to avoid null check errors
    } catch (e) {
      print("Error initializing permissions: $e");
    }
  }

  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
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

  Future<void> _subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
