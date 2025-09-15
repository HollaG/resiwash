import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_list_state.dart';

class MachineListCubit extends Cubit<MachineListState> {
  final ListMachinesUseCase listMachinesUseCase; // <-- depend on the use case

  MachineListCubit({required this.listMachinesUseCase})
    : super(const MachineListInitial());

  Future<void> load({
    List<String>? roomIds,
    List<String>? areaIds,
    List<String>? machineIds,
    bool? min,
    bool? extra,
  }) async {
    if (state is MachineListLoaded) {
      emit(MachineListRefreshing((state as MachineListLoaded).machines));
    } else {
      emit(const MachineListLoading());
    }
    final params = ListMachinesParams(
      roomIds: roomIds,
      areaIds: areaIds,
      machineIds: machineIds,
      min: min,
      extra: extra ?? false,
    );

    final result = await listMachinesUseCase.call(params);

    appLog.d('[MachineListCubit] Loaded machines: $result');
    result.fold(
      (failure) => emit(MachineListError(failure.toString())),
      (machines) => emit(MachineListLoaded(machines)),
    );
  }

  /// Convenience method for loading with just roomIds (backward compatibility)
  Future<void> loadByRoomIds(List<String> roomIds, {bool extra = false}) async {
    await load(roomIds: roomIds, extra: extra);
  }

  /// Convenience method for loading with just areaIds
  Future<void> loadByAreaIds(List<String> areaIds, {bool extra = false}) async {
    await load(areaIds: areaIds, extra: extra);
  }

  /// Convenience method for loading with just machineIds
  Future<void> loadByMachineIds(
    List<String> machineIds, {
    bool extra = false,
  }) async {
    await load(machineIds: machineIds, extra: extra);
  }
}
