import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/features/machine/data/datasource/machine_remote_datasource.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/params/claim_machine_params.dart';
import 'package:resiwash/features/machine/domain/params/get_machine_params.dart';
import 'package:resiwash/features/machine/domain/params/unclaim_machine_params.dart';
import 'package:resiwash/features/machine/domain/repository/machine_repository.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';

class MachineRepositoryImpl implements MachineRepository {
  MachineRemoteDatasource dataSource;
  MachineRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<MachineEntity>>> getMachines(
    ListMachinesParams params,
  ) async {
    try {
      appLog.d("Fetching machines with params: $params");
      final machines = await dataSource.getMachines(params);
      appLog.d("Fetched machines: $machines");
      return Right(machines);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, MachineEntity>> getMachineById({
    required String machineId,
    GetMachineParams? params,
  }) async {
    try {
      final machine = await dataSource.getMachineById(
        machineId: machineId,
        params: params,
      );
      return Right(machine);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, void>> unclaimMachine({
    required String machineId,
    required UnclaimMachineParams params,
  }) async {
    try {
      await dataSource.unclaimMachine(machineId: machineId, params: params);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, void>> claimMachine({
    required String machineId,
    required ClaimMachineParams params,
  }) async {
    try {
      await dataSource.claimMachine(machineId: machineId, params: params);
      return const Right(null);
    } on Failure catch (e) {
      print("MachineRepositoryImpl claimMachine error: ${e.message}");
      return Left(e);
    } catch (e) {
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, void>> updateClaim({
    required String machineId,
    required ClaimMachineParams params,
  }) async {
    try {
      await dataSource.claimMachine(machineId: machineId, params: params);
      return const Right(null);
    } on Failure catch (e) {
      print("MachineRepositoryImpl claimMachine error: ${e.message}");
      return Left(e);
    } catch (e) {
      return Left(Failure());
    }
  }
}
