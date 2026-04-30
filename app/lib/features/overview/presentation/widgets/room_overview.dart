import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/core/widgets/status_row_summary.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/room/domain/entities/room_entity.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';
import 'package:resiwash/router.dart';

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
          final room = state.getRoomById(roomId);
          final area = state.getAreaOfRoom(roomId);
          return InkWell(
            onTap: () => {
              // navigate to specific room page
              context.pushNamed(
                'machines',

                queryParameters: {
                  'roomIds[]': [roomId],
                },

                extra: {
                  'title': room.name,
                  'count': machines.length.toString(),
                },
              ),
            },
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    '${area.shortName != null ? "${area.shortName} " : ""}${room.name}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  // Display machines in this room
                  Column(
                    children: [
                      StatusRowSummary(
                        label: "Dryers",
                        machines: machines
                            .filter(
                              (machine) => machine.type == MachineType.dryer,
                            )
                            .toList(),
                      ),
                      StatusRowSummary(
                        label: "Washers",
                        machines: machines
                            .filter(
                              (machine) => machine.type == MachineType.washer,
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Container();
      },
    );
  }
}
