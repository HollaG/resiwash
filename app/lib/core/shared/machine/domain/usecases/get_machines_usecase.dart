import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/shared/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/core/shared/machine/domain/repository/machine_repository.dart';

class GetMachinesUseCase {
  final MachineRepository repository;

  GetMachinesUseCase({required this.repository});

  Future<Either<Failure, List<MachineEntity>>> call({
    List<String>? roomIds,
  }) async {
    return await repository.getMachines(roomIds: roomIds);
  }
}
