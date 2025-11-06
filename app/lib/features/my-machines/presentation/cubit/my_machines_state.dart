import 'package:equatable/equatable.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

abstract class MyMachinesState extends Equatable {
  const MyMachinesState();

  @override
  List<Object?> get props => [];
}

class MyMachinesInitial extends MyMachinesState {}

class MyMachinesLoading extends MyMachinesState {}

class MyMachinesLoaded extends MyMachinesState {
  final List<String> subscribedMachineIds;
  final List<MachineEntity>? machines;
  final List<ClaimedMachineMetadata> claimedMachineMetadata;

  const MyMachinesLoaded({
    required this.subscribedMachineIds,
    this.machines,
    required this.claimedMachineMetadata,
  });

  @override
  List<Object?> get props => [
    subscribedMachineIds,
    machines,
    claimedMachineMetadata,
  ];
}

class MyMachinesError extends MyMachinesState {
  final String message;

  const MyMachinesError({required this.message});

  @override
  List<Object?> get props => [message];
}

// State for individual operations
class MyMachinesOperationInProgress extends MyMachinesState {
  final List<String> subscribedMachineIds;
  final String operatingMachineId;

  const MyMachinesOperationInProgress({
    required this.subscribedMachineIds,
    required this.operatingMachineId,
  });

  @override
  List<Object?> get props => [subscribedMachineIds, operatingMachineId];
}
