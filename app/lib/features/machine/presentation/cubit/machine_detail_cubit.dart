import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/features/machine/domain/params/get_machine_params.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_state.dart';

import 'package:resiwash/core/extensions/safecubit.dart';

class MachineDetailCubit extends Cubit<MachineDetailState> {
  final GetMachineUseCase getMachineUseCase; // <-- depend on the use case

  MachineDetailCubit({required this.getMachineUseCase})
    : super(const MachineDetailInitial());

  Future<void> load({required String machineId, bool? min, bool? extra}) async {
    if (state is MachineDetailLoaded) {
      safeEmit(MachineDetailRefreshing((state as MachineDetailLoaded).machine));
    } else {
      safeEmit(const MachineDetailLoading());
    }

    final params = GetMachineParams(extra: extra ?? false);

    final result = await getMachineUseCase.call(
      machineId: machineId,
      params: params,
    );

    appLog.d('[MachineDetailCubit] Loaded machines: $result');
    result.fold(
      (failure) => safeEmit(MachineDetailError(failure.message)),
      (machine) => safeEmit(MachineDetailLoaded(machine)),
    );
  }
}
