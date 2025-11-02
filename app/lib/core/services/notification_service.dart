import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    // unique ID
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // when app is minimized
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // when app is open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked! ${message.messageId}');
    });

    // NOTE: Background message handler must be registered in main.dart as a top-level function
    // Do not register it here to avoid null check errors
  }
}
