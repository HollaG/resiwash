import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/shared/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/core/shared/room/presentation/cubit/room_cubit.dart';
import 'package:resiwash/core/shared/room/presentation/cubit/room_state.dart';
import 'package:resiwash/features/Summary/presentation/widgets/homeHeader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final getRoomUsecase = sl<GetRoomUsecase>(instanceName: "getRoomUsecase");

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() async {
    print("running get data");
    final roomCubit = sl<RoomCubit>(instanceName: 'roomCubit');
    roomCubit.getRoom("2", "3");
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, state) {
        print(state);
        if (state is RoomLoaded) {
          // print
          print(state.room);
        }
        return Scaffold(
          // appBar: AppBarComponent(actions: [], title: "ResiWash"),
          body: Column(children: [HomeHeader(username: "Marcus")]),
        );
      },
    );
  }
}
