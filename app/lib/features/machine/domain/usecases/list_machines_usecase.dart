import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/repository/machine_repository.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';

class ListMachinesUseCase {
  final MachineRepository repository;

  ListMachinesUseCase({required this.repository});

  Future<Either<Failure, List<MachineEntity>>> call(
    ListMachinesParams params,
  ) async {
    return await repository.getMachines(params);
  }
}
