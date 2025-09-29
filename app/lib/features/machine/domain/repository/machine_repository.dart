import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/params/get_machine_params.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';

abstract interface class MachineRepository {
  Future<Either<Failure, List<MachineEntity>>> getMachines(
    ListMachinesParams params,
  );

  Future<Either<Failure, MachineEntity>> getMachineById({
    required String machineId,
    GetMachineParams params,
  });
}
