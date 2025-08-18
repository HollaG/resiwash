import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/shared/machine/domain/entities/machine_entity.dart';

import 'package:resiwash/core/shared/machine/domain/usecases/list_machines_usecase.dart';
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

    final listMachinesEither = await listMachinesUseCase.call(roomIds: roomIds);
    final listLocationsEither = await listLocationsUseCase.call();

    print("either");
    appLog.d("either: $listMachinesEither");
    listMachinesEither.match(
      (failure) =>
          emit(OverviewError(failure.message ?? 'Something went wrong')),
      (machines) {
        emit(
          OverviewLoaded(
            machines: machines,
            machinesByRoom: _groupMachinesByRoom(machines),
          ),
        );
      },
    );
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
