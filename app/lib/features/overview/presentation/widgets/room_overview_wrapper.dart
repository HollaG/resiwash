import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';
import 'package:resiwash/features/overview/presentation/widgets/room_overview.dart';

class RoomOverviewWrapper extends StatelessWidget {
  final List<String> roomIds;

  RoomOverviewWrapper({required this.roomIds});

  // already fetched in the parent widget
  // so we can use the machines by room

  @override
  Widget build(BuildContext context) {
    // This widget would typically use the roomIds to fetch and display
    // the overview of each room, possibly using a ListView or GridView.
    return BlocBuilder<OverviewCubit, OverviewState>(
      builder: (context, state) {
        if (state is OverviewLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is OverviewError) {
          return Center(child: Text(state.message));
        } else if (state is OverviewLoaded) {
          // Use the machinesByRoom from the state
          final machinesByRoom = state.machinesByRoom;

          // // Filter machines for the provided roomIds
          // final filteredMachines = roomIds
          //     .map((roomId) => machinesByRoom[roomId] ?? [])
          //     .expand((machines) => machines)
          //     .toList();

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Rooms"),
                ...roomIds.map((roomId) {
                  return RoomOverview(roomId: roomId);
                }),
              ],
            ),
          );
        }
        return Container();
      },
    );
  }
}
