import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/shared/machine/domain/usecases/get_machines_usecase.dart';
import 'package:resiwash/core/shared/mixins/error_handler_mixin.dart';
import 'package:resiwash/core/shared/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/core/shared/room/presentation/cubit/room_cubit.dart';
import 'package:resiwash/core/shared/room/presentation/cubit/room_state.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';
import 'package:resiwash/features/overview/presentation/widgets/homeHeader.dart';
import 'package:resiwash/features/overview/presentation/widgets/room_overview_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with ErrorHandlerMixin {
  final getRoomUsecase = sl<GetRoomUsecase>(instanceName: "getRoomUsecase");

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          OverviewCubit(getMachinesUseCase: sl<GetMachinesUseCase>())
            ..load(roomIds: ["2", "3"]),

      child: BlocConsumer<OverviewCubit, OverviewState>(
        listener: (context, state) {
          // Listen for error states and show toast
          if (state is OverviewError) {
            showErrorMessage(
              state.message,
              onRetry: () {
                context.read<OverviewCubit>().refresh(roomIds: ["2", "3"]);
              },
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            // appBar: AppBarComponent(actions: [], title: "ResiWash"),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(username: "Marcus"),
                RoomOverviewWrapper(roomIds: ["2", "3", "4", "5"]),
              ],
            ),
          );
        },
      ),
    );
  }
}
