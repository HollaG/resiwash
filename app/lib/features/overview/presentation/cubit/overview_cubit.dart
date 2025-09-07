import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';

import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/features/area/domain/usecases/list_locations_use_case.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';

class OverviewCubit extends Cubit<OverviewState> {
  final ListMachinesUseCase listMachinesUseCase; // <-- depend on the use case
  final ListLocationsUseCase listLocationsUseCase;

  OverviewCubit({
    required this.listMachinesUseCase,
    required this.listLocationsUseCase,
  }) : super(OverviewInitial());

  Future<void> load({List<String>? roomIds}) async {
    emit(OverviewLoading());

    appLog.d("Loading overview for roomIds: $roomIds");

    final listMachineParams = ListMachinesParams(roomIds: roomIds);
    final listMachinesEither = await listMachinesUseCase.call(
      listMachineParams,
    );
    final listLocationsEither = await listLocationsUseCase.call();

    appLog.d("listMachinesEither: $listMachinesEither");
    appLog.d("listLocationsEither: $listLocationsEither");

    if (listMachinesEither.isRight() && listLocationsEither.isRight()) {
      final machines = listMachinesEither.fold(
        (l) => <MachineEntity>[],
        (r) => r,
      );
      final locations = listLocationsEither.fold(
        (l) => <AreaEntity>[],
        (r) => r,
      ); // Replace dynamic with your LocationEntity if you have one
      emit(
        OverviewLoaded(
          machines: machines,
          machinesByRoom: _groupMachinesByRoom(machines),
          locations: locations,
        ),
      );
    } else {
      final machineFailure = listMachinesEither.swap().getLeft().toNullable();
      final locationFailure = listLocationsEither.swap().getLeft().toNullable();
      appLog.e("Machine failure: $machineFailure");
      appLog.e("Location failure: $locationFailure");

      emit(OverviewError("Failed to load overview data"));
    }
  }

  Future<void> refresh({List<String>? roomIds}) => load(roomIds: roomIds);
}

Map<String, List<MachineEntity>> _groupMachinesByRoom(
  List<MachineEntity> machines,
) {
  final Map<String, List<MachineEntity>> machinesByRoom = {};

  for (var machine in machines) {
    if (!machinesByRoom.containsKey(machine.roomId)) {
      machinesByRoom[machine.roomId] = [];
    }
    machinesByRoom[machine.roomId]!.add(machine);
  }

  return machinesByRoom;
}
