import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

import 'package:resiwash/core/logging/logger.dart';

class LocalNotificationHandler {
  // Private constructor
  LocalNotificationHandler._();

  // Single instance
  static final LocalNotificationHandler _instance =
      LocalNotificationHandler._();

  // Getter to access the instance
  static LocalNotificationHandler get instance => _instance;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AndroidNotificationChannel channel;
  late DarwinNotificationCategory darwinChannel;

  // called once only
  Future<void> setupLocalNotifications() async {
    // create the 'max' importance channel for Android and iOS
    channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    // iOS has no such required setting
    darwinChannel = DarwinNotificationCategory(
      'high_importance_channel',
      // options: <DarwinNotificationCategoryOption>{
      //   DarwinNotificationCategoryOption.customDismissAction,
      // },
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // create the notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void showSimpleNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      // 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    var darwinPlatformChannelSpecifics = DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Hello!',
      'This is a simple notification.',
      platformChannelSpecifics,
    );
  }

  void showFirebaseNotification(RemoteMessage message) async {
    appLog.d("[LocalNotificationHandler] showFirebaseNotification: $message");
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification?.title,
      notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: android?.smallIcon,
          // other properties...
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: darwinChannel.identifier,
        ),
      ),
    );
  }
}
