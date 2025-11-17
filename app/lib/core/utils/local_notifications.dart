import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/core/utils/datetime_utils.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'dart:async';

import "package:resiwash/features/machine/data/models/machine_model.dart";

import '../../main.dart'; // import your global flutterLocalNotificationsPlugin

class LocalNotificationHandler {
  // Singleton
  LocalNotificationHandler._();
  static final LocalNotificationHandler _instance =
      LocalNotificationHandler._();
  static LocalNotificationHandler get instance => _instance;

  // Channels
  late AndroidNotificationChannel subscriptionChannel;
  late AndroidNotificationChannel claimedChannel;
  late AndroidNotificationChannel pokeChannel;

  // TOOD: ios equivalent
  late AndroidNotificationChannel channelCountdown =
      const AndroidNotificationChannel(
        'countdown_channel',
        'Countdown Notifications',
        description: 'Notifications for countdown timers.',
        importance: Importance.high,
      );

  // IOS categories
  late DarwinNotificationCategory subscriptionCategory;
  late DarwinNotificationCategory claimedCategory;
  late DarwinNotificationCategory pokeCategory;

  // action IDs
  static const String stopClaimActionId = 'stop_claim';
  static const String acknowledgePokeActionId = 'acknowledge_poke';

  // static Notification IDs
  static const int claimedTimerNotificationId = 0;

  // Called once in main()
  Future<void> setupLocalNotifications() async {
    // -----------------------------
    // ANDROID CHANNELS
    // -----------------------------
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
      importance: Importance.max, // HEADS UP
    );

    pokeChannel = const AndroidNotificationChannel(
      'poke',
      'Poke Reminders',
      description: 'Reminders to clear your claimed machine.',
      importance: Importance.high,
    );

    // CREATE ALL CHANNELS
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(subscriptionChannel);
    await androidPlugin?.createNotificationChannel(claimedChannel);
    await androidPlugin?.createNotificationChannel(pokeChannel);

    // -----------------------------
    // IOS CATEGORIES
    // -----------------------------
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
    // plugin already global, but isolate does not share it
    // const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // const iosInit = DarwinInitializationSettings();
    // const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    // await flutterLocalNotificationsPlugin.initialize(settings);

    // // Recreate channels (safe because Android ignores duplicates)
    // final androidPlugin = flutterLocalNotificationsPlugin
    //     .resolvePlatformSpecificImplementation<
    //       AndroidFlutterLocalNotificationsPlugin
    //     >();

    // await androidPlugin?.createNotificationChannel(subscriptionChannel);
    // await androidPlugin?.createNotificationChannel(claimedChannel);
    // await androidPlugin?.createNotificationChannel(pokeChannel);

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
    await LocalNotificationHandler.instance.setupLocalNotifications();
  }
  // ---------------------------------
  // HANDLERS
  // ---------------------------------
  // data: {
  //     machineId: machine.machineId.toString(),
  //     machineName: machine.name,
  //     machineRoomName: machine.room.name,
  //     machineAreaShortName: machine.room.area.shortName,
  //     machineCurrentStatus: machine.currentStatus,
  //     machinePreviousStatus: machine.previousStatus,

  //     channel: "claimed",
  //   },
  void handleClaimedDataNotification(RemoteMessage message) {
    final data = message.data;
    final machineId = data['machineId'] as String?;
  }

  // -------------------------------------------------------
  // USE CORRECT CHANNELS
  // -------------------------------------------------------

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

  // Show a persistent timer, with the end time being cycle time + lastAvailableTime
  // should ONLY be called when the machine status changes to "IN_USE"
  // TODO: iOS implementation
  void _showClaimedTime(
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
    final AndroidNotificationDetails
    androidNotificationDetailsChronotmeter = AndroidNotificationDetails(
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
      // largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      chronometerCountDown: true,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
      // actions: const [
      //   AndroidNotificationAction('pause', 'PAUSE', cancelNotification: false),
      //   AndroidNotificationAction('stop', 'STOP', cancelNotification: true),
      // ],
    );
    flutterLocalNotificationsPlugin.show(
      claimedTimerNotificationId,
      "${machine.name} @ ${machine.room?.name} running...",
      "Expected to finish by $expectedEndTime",
      NotificationDetails(android: androidNotificationDetailsChronotmeter),
    );
  }

  void _showClaimFinishingSoonNotification(
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

    final AndroidNotificationDetails
    androidNotificationDetailsChronotmeter = AndroidNotificationDetails(
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
      // largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      chronometerCountDown: true,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
      // actions: const [
      //   AndroidNotificationAction('pause', 'PAUSE', cancelNotification: false),
      //   AndroidNotificationAction('stop', 'STOP', cancelNotification: true),
      // ],
    );

    flutterLocalNotificationsPlugin.show(
      claimedTimerNotificationId,
      "${machine.name} finishing soon!",
      "Please prepare to clear your laundry. Expected to finish by $expectedEndTime",
      NotificationDetails(android: androidNotificationDetailsChronotmeter),
    );
  }

  void _showClaimCompletedNotification(MachineEntity machine) {
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
              LocalNotificationHandler.stopClaimActionId,
              'Stop alerts',
              showsUserInterface:
                  true, // impt: see https://pub.dev/packages/flutter_local_notifications#notification-actions
            ),
            AndroidNotificationAction(
              LocalNotificationHandler.acknowledgePokeActionId,
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

  // display a notification, depending on the status:
  // inuse: showClaimedTime
  // finishing: showClaimFinishingSoonNotification
  // done: showClaimCompletedNotification
  void showClaimedNotification(
    MachineEntity machine,
    ClaimedMachineMetadata metadata,
  ) {
    switch (machine.currentStatus) {
      case MachineStatus.inUse:
        _showClaimedTime(machine, metadata);
        break;
      case MachineStatus.finishing:
        _showClaimFinishingSoonNotification(machine, metadata);
        break;
      case MachineStatus.available:
        _showClaimCompletedNotification(machine);
        break;
      default:
        // do nothing
        break;
    }
  }
}
