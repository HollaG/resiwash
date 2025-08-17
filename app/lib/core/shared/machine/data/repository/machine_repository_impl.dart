import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/shared/machine/data/datasource/machine_remote_datasource.dart';
import 'package:resiwash/core/shared/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/core/shared/machine/domain/repository/machine_repository.dart';

class MachineRepositoryImpl implements MachineRepository {
  MachineRemoteDatasource dataSource;
  MachineRepositoryImpl({required this.dataSource});
  @override
  Future<Either<Failure, List<MachineEntity>>> getMachines({
    List<String>? roomIds = const [],
  }) async {
    try {
      appLog.d("Fetching machines for roomIds: $roomIds");
      final machines = await dataSource.getMachines(roomIds: roomIds);
      appLog.d("Fetched machines: $machines");
      return Right(machines);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, MachineEntity>> getMachineById({
    required String machineId,
  }) async {
    try {
      final machine = await dataSource.getMachineById(machineId: machineId);
      return Right(machine);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      return Left(Failure());
    }
  }
}
