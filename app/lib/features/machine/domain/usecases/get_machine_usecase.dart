import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/params/get_machine_params.dart';
import 'package:resiwash/features/machine/domain/repository/machine_repository.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';

class GetMachineUseCase {
  final MachineRepository repository;

  GetMachineUseCase({required this.repository});

  Future<Either<Failure, MachineEntity>> call({
    required String machineId,
    required GetMachineParams params,
  }) async {
    return await repository.getMachineById(
      machineId: machineId,
      params: params,
    );
  }
}
