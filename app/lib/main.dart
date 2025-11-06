import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/services/notification_service.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_cubit.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/router.dart';
import 'package:flutter/material.dart';
import 'util.dart';
import 'theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // IMPORTANT: This must be a top-level function
  // Initialize Firebase in the background isolate
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupServiceLocator();

  // Register the background message handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // final notificationService = NotificationService();
  // await notificationService.initialize();

  // get the service from Sl
  final notificationService = sl<NotificationService>();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(context);

    MaterialTheme theme = MaterialTheme(textTheme);

    final routerBuild = MaterialApp.router(
      routerConfig: router,
      title: 'ResiWash',
      theme: theme.light().copyWith(textTheme: textTheme),
      darkTheme: theme.dark().copyWith(textTheme: textTheme),
      themeMode: ThemeMode.light, // TODO: enable system dark mode
    );

    // return MaterialApp(
    //   home: Scaffold(
    //     appBar: AppBar(title: Text('Firebase Notifications')),
    //     body: NotificationWidget(),
    //   ),
    // );

    // only for global dependencies
    return MultiBlocProvider(
      providers: [
        // MyMachinesCubit - shared across all pages
        BlocProvider(
          create: (context) => sl<MyMachinesCubit>()..loadNotifyableMachines(),
        ),
        // todo: remove this one
        BlocProvider(
          create: (context) => sl<RoomDetailCubit>(instanceName: 'roomCubit'),
        ),
      ],
      child: routerBuild,
    );
  }
}
