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

// This event will only happen after the machines have loaded.
// covers Subscribing and Unsubscribing states
class MyMachinesSubscribing extends MyMachinesLoaded {
  const MyMachinesSubscribing({
    required super.subscribedMachineIds,
    super.machines,
    required super.claimedMachineMetadata,
  });
}

class MyMachinesSubscribed extends MyMachinesLoaded {
  final MachineEntity operatingMachine;

  const MyMachinesSubscribed({
    required super.subscribedMachineIds,
    super.machines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
  });
  @override
  List<Object?> get props => [...super.props, operatingMachine];
}

// This event will only happen after the machines have loaded.
// covers Subscribing and unclaiming states
class MyMachinesClaiming extends MyMachinesLoaded {
  const MyMachinesClaiming({
    required super.subscribedMachineIds,
    super.machines,
    required super.claimedMachineMetadata,
  });
}

class MyMachinesClaimed extends MyMachinesLoaded {
  final MachineEntity operatingMachine;

  const MyMachinesClaimed({
    required super.subscribedMachineIds,
    super.machines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
  });
  @override
  List<Object?> get props => [...super.props, operatingMachine];
}
