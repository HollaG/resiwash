import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/machine/domain/params/claim_machine_params.dart';
import 'package:resiwash/features/machine/domain/params/unclaim_machine_params.dart';
import 'package:resiwash/features/machine/domain/repository/machine_repository.dart';

class MyMachinesUseCase {
  final MachineRepository repository;

  MyMachinesUseCase({required this.repository});

  // Additional operations
  Future<Either<Failure, void>> claim(
    String machineId, {
    required int cycleTime,
    required String fcmToken,
  }) async {
    return await repository.claimMachine(
      machineId: machineId,
      params: ClaimMachineParams(cycleTime: cycleTime, fcmToken: fcmToken),
    );
  }

  Future<Either<Failure, void>> unclaim(
    String machineId, {
    required String fcmToken,
  }) async {
    return await repository.unclaimMachine(
      machineId: machineId,
      params: UnclaimMachineParams(fcmToken: fcmToken),
    );
  }
}
