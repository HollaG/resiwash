import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/router.dart';
import 'package:flutter/material.dart';
import 'util.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
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
      title: 'Flutter Demo',
      theme: theme.light().copyWith(textTheme: textTheme),
      darkTheme: theme.dark().copyWith(textTheme: textTheme),
      themeMode: ThemeMode.system,
    );

    // only for global dependencies
    return MultiBlocProvider(
      providers: [
        // todo: remove this one
        BlocProvider(
          create: (context) => sl<RoomDetailCubit>(instanceName: 'roomCubit'),
        ),
      ],
      child: routerBuild,
    );
  }
}
