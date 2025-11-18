import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

/// Base state for claim management
abstract class ClaimState {
  final List<ClaimedMachineMetadata> claimedMachineMetadata;
  final List<MachineEntity>? claimedMachines;

  const ClaimState({
    required this.claimedMachineMetadata,
    this.claimedMachines,
  });
}

/// Initial state
class ClaimInitial extends ClaimState {
  const ClaimInitial() : super(claimedMachineMetadata: const []);
}

/// Loading claimed machines
class ClaimLoading extends ClaimState {
  const ClaimLoading({
    required super.claimedMachineMetadata,
    super.claimedMachines,
  });
}

/// Claimed machines loaded successfully
class ClaimLoaded extends ClaimState {
  const ClaimLoaded({
    required super.claimedMachineMetadata,
    required super.claimedMachines,
  });
}

/// Refreshing claimed machines list
class ClaimRefreshing extends ClaimLoaded {
  const ClaimRefreshing({
    required super.claimedMachineMetadata,
    required super.claimedMachines,
  });
}

/// Currently claiming/unclaiming a machine
class Claiming extends ClaimLoaded {
  final MachineEntity operatingMachine;

  const Claiming({
    required super.claimedMachineMetadata,
    required super.claimedMachines,
    required this.operatingMachine,
  });
}

/// Successfully claimed a machine
class Claimed extends ClaimLoaded {
  final MachineEntity operatingMachine;

  const Claimed({
    required super.claimedMachineMetadata,
    required super.claimedMachines,
    required this.operatingMachine,
  });
}

/// Successfully unclaimed a machine
class Unclaimed extends ClaimLoaded {
  final MachineEntity operatingMachine;

  const Unclaimed({
    required super.claimedMachineMetadata,
    required super.claimedMachines,
    required this.operatingMachine,
  });
}

/// Error claiming/unclaiming
class ClaimOperationError extends ClaimLoaded {
  final String message;
  final MachineEntity operatingMachine;

  const ClaimOperationError({
    required super.claimedMachineMetadata,
    required super.claimedMachines,
    required this.message,
    required this.operatingMachine,
  });
}

/// Error loading claimed machines
class ClaimError extends ClaimState {
  final String message;

  const ClaimError({required this.message})
    : super(claimedMachineMetadata: const []);
}
