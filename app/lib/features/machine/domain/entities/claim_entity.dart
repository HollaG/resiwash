import 'package:equatable/equatable.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

class ClaimEntity extends Equatable {
  final int claimId;
  final String? fcmToken;
  final int cycleTime;
  final int machineId;
  final DateTime claimedAt;
  final MachineEntity? machine;

  const ClaimEntity({
    required this.claimId,
    this.fcmToken,
    required this.cycleTime,
    required this.machineId,
    required this.claimedAt,
    this.machine,
  });

  @override
  String toString() {
    return 'ClaimEntity(claimId: $claimId, fcmToken: $fcmToken, cycleTime: $cycleTime, machineId: $machineId, claimedAt: $claimedAt, machine: $machine)';
  }

  @override
  List<Object?> get props => [
    claimId,
    fcmToken,
    cycleTime,
    machineId,
    claimedAt,
    machine,
  ];
}
