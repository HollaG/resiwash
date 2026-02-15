import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/core/utils/datetime_utils.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'dart:async';

import "package:resiwash/features/machine/data/models/machine_model.dart";

import '../../main.dart'; // import your global flutterLocalNotificationsPlugin

/// Service for managing local notifications
///
/// This service handles:
/// - Creating and managing notification channels (Android) / categories (iOS)
/// - Showing different types of notifications (subscribed, claimed, poke)
/// - Managing persistent notifications (timers, countdowns)
class LocalNotificationService {
  // Channels
  late AndroidNotificationChannel subscriptionChannel;
  late AndroidNotificationChannel claimedChannel;
  late AndroidNotificationChannel pokeChannel;
  late AndroidNotificationChannel channelCountdown;

  // iOS categories
  late DarwinNotificationCategory subscriptionCategory;
  late DarwinNotificationCategory claimedCategory;
  late DarwinNotificationCategory pokeCategory;

  // action IDs
  static const String stopClaimActionId = 'stop_claim';
  static const String acknowledgePokeActionId = 'acknowledge_poke';

  // static Notification IDs
  static const int claimedTimerNotificationId = 0;

  // Initialize notification channels and categories
  Future<void> initialize() async {
    await _setupAndroidChannels();
    await _setupIOSCategories();
  }

  Future<void> _setupAndroidChannels() async {
    subscriptionChannel = const AndroidNotificationChannel(
      'subscriptions',
      'Subscribed Machine Updates',
      description: 'Notifications for machines you subscribed to.',
      importance: Importance.defaultImportance,
    );

    claimedChannel = const AndroidNotificationChannel(
      'claimed',
      'Claimed Machine Updates',
      description: 'High priority alerts for claimed machines.',
      importance: Importance.max,
    );

    pokeChannel = const AndroidNotificationChannel(
      'poke',
      'Poke Reminders',
      description: 'Reminders to clear your claimed machine.',
      importance: Importance.high,
    );

    channelCountdown = const AndroidNotificationChannel(
      'countdown_channel',
      'Countdown Notifications',
      description: 'Notifications for countdown timers.',
      importance: Importance.high,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(subscriptionChannel);
    await androidPlugin?.createNotificationChannel(claimedChannel);
    await androidPlugin?.createNotificationChannel(pokeChannel);
    await androidPlugin?.createNotificationChannel(channelCountdown);
  }

  Future<void> _setupIOSCategories() async {
    subscriptionCategory = const DarwinNotificationCategory('subscriptions');
    claimedCategory = const DarwinNotificationCategory('claimed');
    pokeCategory = DarwinNotificationCategory(
      'poke',
      actions: [
        DarwinNotificationAction.plain(
          'stop_claim',
          'Stop alerts',
          options: {DarwinNotificationActionOption.foreground},
        ),
        DarwinNotificationAction.plain(
          'acknowledge_poke',
          'Acknowledge',
          options: {DarwinNotificationActionOption.foreground},
        ),
      ],
    );
  }

  // Called for setup in background handler
  Future<void> ensureInitializedForBackground() async {
    const initAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initIOS = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: notificationTapBackground,
    );

    await initialize();
  }

  void showSubscribed(RemoteMessage msg) {
    final n = msg.notification;
    final a = msg.notification?.android;

    flutterLocalNotificationsPlugin.show(
      n.hashCode,
      n?.title,
      n?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          subscriptionChannel.id,
          subscriptionChannel.name,
          icon: a?.smallIcon,
          importance: Importance.max,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: subscriptionCategory.identifier,
        ),
      ),
      payload: jsonEncode({
        "machineId": msg.data['machineId'],
        "channel": msg.data['channel'],
      }),
    );
  }

  void showClaimedIncomingNotification(RemoteMessage msg) {
    final n = msg.notification;
    final a = msg.notification?.android;

    flutterLocalNotificationsPlugin.show(
      n.hashCode,
      n?.title,
      n?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          claimedChannel.id,
          claimedChannel.name,
          priority: Priority.high,
          importance: Importance.max,
          icon: a?.smallIcon,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: claimedCategory.identifier,
        ),
      ),
      payload: jsonEncode({
        "machineId": msg.data['machineId'],
        "channel": msg.data['channel'],
      }),
    );
  }

  void showPoke(RemoteMessage msg) {
    final n = msg.data;

    flutterLocalNotificationsPlugin.show(
      n.hashCode,
      n['title'],
      n['body'],
      NotificationDetails(
        android: AndroidNotificationDetails(
          pokeChannel.id,
          pokeChannel.name,
          importance: Importance.max,
          priority: Priority.defaultPriority,
          actions: [
            AndroidNotificationAction(
              stopClaimActionId,
              'Stop alerts',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              acknowledgePokeActionId,
              'Acknowledge',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: pokeCategory.identifier,
        ),
      ),
      payload: jsonEncode({
        "machineId": n['machineId'],
        "channel": n['channel'],
      }),
    );
  }

  // Display a notification depending on machine status
  void __showClaimedNotification(
    MachineEntity machine,
    ClaimedMachineMetadata metadata,
  ) {
    switch (machine.currentStatus) {
      case MachineStatus.inUse:
        _oldshowClaimedTime(machine, metadata);
        break;
      case MachineStatus.finishing:
        _oldshowClaimFinishingSoonNotification(machine, metadata);
        break;
      case MachineStatus.available:
        _oldshowClaimCompletedNotification(machine);
        break;
      default:
        break;
    }
  }

  // void showClaimedNotification(
  //   RemoteMessage msg,
  //   String title,
  //   String body,
  //   int secondsTillCompletion,
  // ) {
  //   final androidDetails = AndroidNotificationDetails(
  //     channelCountdown.id,
  //     channelCountdown.name,
  //     channelDescription: channelCountdown.description,
  //     importance: Importance.max,
  //     priority: Priority.max,
  //     ongoing: true,
  //     when:
  //         DateTime.now().millisecondsSinceEpoch +
  //         (secondsLeftWhenCalled * 1000),
  //     usesChronometer: true,
  //     chronometerCountDown: true,
  //     channelAction: AndroidNotificationChannelAction.createIfNotExists,
  //   );

  //   flutterLocalNotificationsPlugin.show(
  //     claimedTimerNotificationId,
  //     "${machine.name} finishing soon!",
  //     "Please prepare to clear your laundry. Expected to finish by $expectedEndTime",
  //     NotificationDetails(android: androidDetails),
  //   );
  // }

  void _oldshowClaimedTime(
    MachineEntity machine,
    ClaimedMachineMetadata metadata,
  ) {
    final seconds = metadata.cycleTime * 60;
    String expectedEndTime = DateTimeUtils.formatReadableTime(
      machine.lastAvailableTime?.add(Duration(seconds: seconds)),
    );

    final secondsLeftWhenCalled = machine.lastAvailableTime == null
        ? seconds
        : seconds -
              DateTime.now().difference(machine.lastAvailableTime!).inSeconds;

    final androidDetails = AndroidNotificationDetails(
      channelCountdown.id,
      channelCountdown.name,
      channelDescription: channelCountdown.description,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      when:
          DateTime.now().millisecondsSinceEpoch +
          (secondsLeftWhenCalled * 1000),
      usesChronometer: true,
      chronometerCountDown: true,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
    );

    flutterLocalNotificationsPlugin.show(
      claimedTimerNotificationId,
      "${machine.name} @ ${machine.room?.name} running...",
      "Expected to finish by $expectedEndTime",
      NotificationDetails(android: androidDetails),
    );
  }

  void _oldshowClaimFinishingSoonNotification(
    MachineEntity machine,
    ClaimedMachineMetadata metadata,
  ) {
    final seconds = metadata.cycleTime * 60;
    String expectedEndTime = DateTimeUtils.formatReadableTime(
      machine.lastAvailableTime?.add(Duration(seconds: seconds)),
    );
    final secondsLeftWhenCalled = machine.lastAvailableTime == null
        ? seconds
        : seconds -
              DateTime.now().difference(machine.lastAvailableTime!).inSeconds;

    final androidDetails = AndroidNotificationDetails(
      channelCountdown.id,
      channelCountdown.name,
      channelDescription: channelCountdown.description,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      when:
          DateTime.now().millisecondsSinceEpoch +
          (secondsLeftWhenCalled * 1000),
      usesChronometer: true,
      chronometerCountDown: true,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
    );

    flutterLocalNotificationsPlugin.show(
      claimedTimerNotificationId,
      "${machine.name} finishing soon!",
      "Please prepare to clear your laundry. Expected to finish by $expectedEndTime",
      NotificationDetails(android: androidDetails),
    );
  }

  void _oldshowClaimCompletedNotification(MachineEntity machine) {
    flutterLocalNotificationsPlugin.show(
      claimedTimerNotificationId,
      "${machine.name} is done!",
      "Please clear your machine in the laundry room as soon as possible.",
      NotificationDetails(
        android: AndroidNotificationDetails(
          claimedChannel.id,
          claimedChannel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void showClaimedMachineNowAvailableNotification(String title, String body) {
    // 1. clear the timer notification
    cancelClaimedNotification();

    // 2. display a normal notification saying machine is available
    flutterLocalNotificationsPlugin.show(
      DateTime.now().hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          claimedChannel.id,
          claimedChannel.name,
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: claimedCategory.identifier,
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  void showClaimedMachineNowInUseNotification(
    String title,
    String body,
    int secondsTillCompletion,
  ) {
    appLog.i("Showing claimed machine in use notification: $title");
    // 1. start a system timer (TODO)
    FlutterAlarmClock.createTimer(
      length: secondsTillCompletion,
      title: title,
      skipUi: true,
    );
    // 2. Show a normal notification saying machine is in use
    try {
      appLog.i("Channels initialized: claimed=${claimedChannel.id}");

      final notificationId = DateTime.now().hashCode;
      appLog.i("Using notification ID: $notificationId");

      flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            claimedChannel.id,
            claimedChannel.name,
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: claimedCategory.identifier,
            interruptionLevel: InterruptionLevel.timeSensitive,
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );

      appLog.i('Notification shown successfully');
    } catch (e, stackTrace) {
      appLog.e("Error showing notification: $e");
      appLog.e("Stack: $stackTrace");
    }
  }

  void showClaimedMachineFinishingNotification(
    String title,
    String body,
    int secondsTillCompletion,
  ) {
    // 1. Show a normal notification saying machine is finishing soon
    flutterLocalNotificationsPlugin.show(
      // random ID
      DateTime.now().hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          claimedChannel.id,
          claimedChannel.name,
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: claimedCategory.identifier,
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelClaimedNotification() async {
    await flutterLocalNotificationsPlugin.cancel(claimedTimerNotificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
