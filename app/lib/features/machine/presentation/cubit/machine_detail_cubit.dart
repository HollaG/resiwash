import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/features/machine/domain/params/get_machine_params.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_state.dart';

class MachineDetailCubit extends Cubit<MachineDetailState> {
  final GetMachineUseCase getMachineUseCase; // <-- depend on the use case

  MachineDetailCubit({required this.getMachineUseCase})
    : super(const MachineDetailInitial());

  Future<void> load({required String machineId, bool? min, bool? extra}) async {
    if (state is MachineDetailLoaded) {
      emit(MachineDetailRefreshing((state as MachineDetailLoaded).machine));
    } else {
      emit(const MachineDetailLoading());
    }

    final params = GetMachineParams(extra: extra ?? false);

    final result = await getMachineUseCase.call(
      machineId: machineId,
      params: params,
    );

    appLog.d('[MachineDetailCubit] Loaded machines: $result');
    result.fold(
      (failure) => emit(MachineDetailError(failure.message)),
      (machine) => emit(MachineDetailLoaded(machine)),
    );
  }
}
