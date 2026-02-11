import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/firebase_notification_service.dart';
import 'package:resiwash/core/services/live_notification_service.dart';
import 'package:resiwash/core/services/local_notification_service.dart';
import 'package:resiwash/core/utils/subscription_utils.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_cubit.dart';
import 'package:resiwash/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'util.dart';
import 'theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

/// ------------------------------------------------------------
/// GLOBAL PLUGIN INSTANCE  (IMPORTANT!)
/// ------------------------------------------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// ------------------------------------------------------------
/// FCM BACKGROUND HANDLERS (top-level only)
/// // runs when app is in background or terminated
/// // responsible for SHOWING a notification
/// ------------------------------------------------------------

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  appLog.i('[BG Handler] Received FCM: $message');

  await sl<LocalNotificationService>().ensureInitializedForBackground();

  CustomFirebaseMessageChannel channel = getChannelFromString(
    message.data['channel'],
  );

  if (channel == CustomFirebaseMessageChannel.poke) {
    sl<LocalNotificationService>().showPoke(message);
  } else if (channel == CustomFirebaseMessageChannel.claimed) {
    sl<LocalNotificationService>().showClaimedIncomingNotification(message);
  } else if (channel == CustomFirebaseMessageChannel.subscribed ||
      channel == CustomFirebaseMessageChannel.subscribedGroup) {
    sl<LocalNotificationService>().showSubscribed(message);
  }

  return;
}

@pragma('vm:entry-point')
void notificationTapForeground(NotificationResponse response) {
  appLog.i(
    '[FG Notification tap] $response with payload: ${response.payload} and action ${response.actionId}',
  );

  notificationTapBackground(response);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  appLog.i(
    '[BG Notification tap] $response with payload: ${response.payload} and action ${response.actionId}',
  );

  if (response.actionId == null) {
    // user tapped on the notification itself
    final payload = response.payload;
    if (payload != null) {
      final data = jsonDecode(payload);
      if (data != null &&
          data.containsKey('machineId') &&
          data.containsKey('channel')) {
        final machineId = data['machineId'] as String;
        final channelString = data['channel'] as String;

        final channel = CustomFirebaseMessageChannel.values.firstWhere(
          (e) => e.name == channelString,
          orElse: () => throw Exception("Unknown channel: $channelString"),
        );

        appLog.i(
          "[BG Notification tap] Tapped notification for machineId: $machineId on channel: $channel",
        );

        // Navigate to appropriate screen based on channel
        switch (channel) {
          case CustomFirebaseMessageChannel.subscribedGroup:
          case CustomFirebaseMessageChannel.subscribed:
            // Navigate to machine details page
            final context = navigatorKey.currentContext;
            if (context != null && context.mounted) {
              appLog.d(
                "[BG Notification tap] Navigating to machine detail $machineId",
              );
              // Use pushReplacement to force navigation even if already on a machine detail page
              context.go(AppRoutes.buildMachineDetailRoute(machineId));
            }
            break;
          case CustomFirebaseMessageChannel.claimed:
            // Navigate to My Machines page
            final claimedContext = navigatorKey.currentContext;
            if (claimedContext != null && claimedContext.mounted) {
              claimedContext.go(AppRoutes.myMachines);
            }
            break;
          case CustomFirebaseMessageChannel.poke:
            // Navigate to My Machines page
            final pokeContext = navigatorKey.currentContext;
            if (pokeContext != null && pokeContext.mounted) {
              pokeContext.go(AppRoutes.myMachines);
            }
            break;
        }
      }
    }
  } else {
    switch (response.actionId) {
      case LocalNotificationService.stopClaimActionId:
        {
          // Stop claim alerts
          final payload = response.payload;
          if (payload != null) {
            final data = jsonDecode(payload);
            if (data != null && data.containsKey('machineId')) {
              final machineId = data['machineId'] as String;

              try {
                // Get the ClaimCubit from the app-level BlocProvider
                final claimCubit = sl<ClaimCubit>();

                // Navigate to the My Machines page to show the user what's happening
                navigatorKey.currentState?.pushNamed(AppRoutes.myMachines);

                // Perform the unclaim action
                await claimCubit.loadClaimedMachines(); // ensure latest data
                await claimCubit.unclaimMachineById(machineId);

                scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Successfully stopped claim alerts.')),
                );
                appLog.i(
                  "[BG Notification tap] Stopped claim alerts for machineId: $machineId",
                );
              } catch (e) {
                scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Error stopping claim alerts.')),
                );
                appLog.e(
                  "[BG Notification tap] Error unclaiming machineId: $machineId, error: $e",
                );
              }
            }
          }
          break;
        }
      case LocalNotificationService.acknowledgePokeActionId:
        {
          // Acknowledge poke (TODO implement)
          // final payload = response.payload;
          // if (payload != null) {
          //   final data = parseJsonPayload(payload);
          //   if (data != null && data.containsKey('machineId')) {
          //     final machineId = data['machineId'] as String;
          //     SubscriptionUtils.acknowledgePoke(machineId);
          //     appLog.i(
          //       "[BG Notification tap] Acknowledged poke for machineId: $machineId",
          //     );
          //   }
          // }
          break;
        }
      default:
        {
          appLog.i(
            "[BG Notification tap] No action taken for actionId: ${response.actionId}",
          );
        }
    }
  }
}

/// ------------------------------------------------------------
/// MAIN ENTRYPOINT
/// ------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupServiceLocator();

  // ------------------------------------------------------------
  // 1) INITIALIZE PLUGIN FIRST
  // ------------------------------------------------------------
  const initAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
  const initIOS = DarwinInitializationSettings();

  const initSettings = InitializationSettings(
    android: initAndroid,
    iOS: initIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: notificationTapForeground,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // ------------------------------------------------------------
  // 2) CREATE NOTIFICATION CHANNELS
  // ------------------------------------------------------------
  await sl<LocalNotificationService>().initialize();

  // ------------------------------------------------------------
  // 3) REGISTER FCM BACKGROUND HANDLER (AFTER CHANNELS!)
  // ------------------------------------------------------------
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ------------------------------------------------------------
  // 4) INITIALIZE YOUR SERVICES
  // ------------------------------------------------------------
  await sl<FirebaseNotificationService>().initialize();
  await sl<LiveNotificationService>().initialize();

  // ------------------------------------------------------------
  // 5) RUN THE APP
  // ------------------------------------------------------------
  runApp(const MyApp());
}

/// ------------------------------------------------------------
/// APP ROOT
/// ------------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context);
    MaterialTheme theme = MaterialTheme(textTheme);

    final routerApp = MaterialApp.router(
      routerConfig: router,
      title: 'ResiWash',
      theme: theme.light().copyWith(textTheme: textTheme),
      darkTheme: theme.dark().copyWith(textTheme: textTheme),
      themeMode: ThemeMode.light,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );

    return MultiBlocProvider(
      providers: [
        // Subscription cubit for managing machine notifications
        BlocProvider(
          create: (_) =>
              sl<SubscriptionCubit>()..loadSubscribedEntities(isFresh: true),
        ),
        // Claim cubit for managing claimed machines
        BlocProvider(create: (_) => sl<ClaimCubit>()..loadClaimedMachines()),
        BlocProvider(
          create: (_) => sl<RoomDetailCubit>(instanceName: 'roomCubit'),
        ),
      ],
      child: routerApp,
    );
  }
}
