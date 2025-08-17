import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/shared/machine/domain/entities/machine_entity.dart';

import 'package:resiwash/core/shared/machine/domain/usecases/get_machines_usecase.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';

class OverviewCubit extends Cubit<OverviewState> {
  final GetMachinesUseCase getMachinesUseCase; // <-- depend on the use case
  OverviewCubit({required this.getMachinesUseCase}) : super(OverviewInitial());

  Future<void> load({List<String>? roomIds}) async {
    emit(OverviewLoading());

    final either = await getMachinesUseCase.call(roomIds: roomIds);

    print("either");
    appLog.d("either: $either");
    either.match(
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
