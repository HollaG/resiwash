import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/shared/room/presentation/cubit/room_cubit.dart';
import 'package:resiwash/router.dart';
import 'package:flutter/material.dart';
import 'util.dart';
import 'theme.dart';

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(context, "Open Sans", "Poppins");

    MaterialTheme theme = MaterialTheme(textTheme);

    final routerBuild = MaterialApp.router(
      routerConfig: router,
      title: 'Flutter Demo',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<RoomCubit>(instanceName: 'roomCubit'),
        ),
      ],
      child: routerBuild,
    );
  }
}
