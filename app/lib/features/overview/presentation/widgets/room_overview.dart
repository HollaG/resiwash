import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';

class RoomOverview extends StatelessWidget {
  final String roomId;

  RoomOverview({required this.roomId});

  @override
  Widget build(BuildContext context) {
    // This widget would typically display the overview of the room
    // For example, it could show the room name, status, and a list of machines
    return BlocBuilder<OverviewCubit, OverviewState>(
      builder: (context, state) {
        if (state is OverviewLoaded) {
          final machines = state.getMachinesInRoom(roomId);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Room ID: $roomId"),
              // Display machines in this room
              machines.isEmpty
                  ? Text("No machines found in this room.")
                  : Column(
                      children:
                          state.machinesByRoom[roomId]?.map((machine) {
                            return Text(
                              "Machine ID: ${machine.machineId}, Status: ${machine.currentStatus}",
                            );
                          }).toList() ??
                          [Text("No machines found for this room")],
                    ),
            ],
          );
        }

        return Container();
      },
    );
  }
}
