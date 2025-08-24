import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/features/area/domain/usecases/get_area_use_case.dart';
import 'package:resiwash/features/area/presentation/cubit/area_detail_cubit.dart';
import 'package:resiwash/features/area/presentation/cubit/area_detail_state.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_list_cubit.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_list_state.dart';
import 'package:resiwash/core/shared/mixins/error_handler_mixin.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_list_app_bar.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_cubit.dart';

enum ChipSelectionType { machine, room, status }

class MachineListScreen extends StatefulWidget {
  final String? query;
  final List<String>? areaIds;
  final List<String>? roomIds;
  final List<String>? machineIds;

  final String? title;
  final String? count;

  const MachineListScreen({
    super.key,
    this.query,
    this.areaIds,
    this.roomIds,
    this.machineIds,
    this.title,
    this.count,
  });

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen>
    with ErrorHandlerMixin {
  @override
  Widget build(BuildContext context) {
    // Name logic:
    // if exactly one roomId, display room name
    // if exactly one areaId, display area name
    // else, display "Machines"

    // possible extensions: Washer / Dryer type

    return MultiBlocProvider(
      providers: [
        BlocProvider<MachineListCubit>(
          create: (context) =>
              MachineListCubit(listMachinesUseCase: sl<ListMachinesUseCase>())
                ..load(roomIds: widget.roomIds),
        ),
      ],
      child: Scaffold(
        appBar: MachineListAppBar(
          roomIds: widget.roomIds ?? [],
          areaIds: widget.areaIds ?? [],
          title: widget.title,
          count: widget.count,
        ),
        body: BlocConsumer<MachineListCubit, MachineListState>(
          listener: (context, state) {
            // Listen for error states and show toast
            if (state is MachineListError) {
              showErrorMessage(state.message, onRetry: () {});
            }
          },
          builder: (context, state) {
            if (state is MachineListLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is MachineListLoaded) {
              return Container(
                padding: EdgeInsets.all(16),
                child: ListView(
                  children: state.machines.map((machine) {
                    return MachineRow(machine: machine);
                  }).toList(),
                ),
              );
            }

            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
