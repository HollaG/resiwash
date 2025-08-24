import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

abstract interface class MachineRepository {
  Future<Either<Failure, List<MachineEntity>>> getMachines({
    List<String>? roomIds = const [],
  });
  Future<Either<Failure, MachineEntity>> getMachineById({
    required String machineId,
  });
}
