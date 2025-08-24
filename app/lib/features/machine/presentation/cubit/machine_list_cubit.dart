import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_list_state.dart';

class MachineListCubit extends Cubit<MachineListState> {
  final ListMachinesUseCase listMachinesUseCase; // <-- depend on the use case

  MachineListCubit({required this.listMachinesUseCase})
    : super(const MachineListInitial());

  Future<void> load({List<String>? roomIds}) async {
    emit(const MachineListLoading());
    final result = await listMachinesUseCase.call(roomIds: roomIds);

    appLog.d('Loaded machines: $result');
    result.fold(
      (failure) => emit(MachineListError(failure.toString())),
      (machines) => emit(MachineListLoaded(machines)),
    );
  }
}
