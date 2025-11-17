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

// Assertion: MyMachinesClaimed and MyMachinesSubscribed will always emit MyMachinesLoaded after 1 second
class MyMachinesLoaded extends MyMachinesState {
  final List<String> subscribedMachineIds;
  final List<MachineEntity> subscribedMachines;
  final List<ClaimedMachineMetadata> claimedMachineMetadata;
  final List<MachineEntity> claimedMachines;

  const MyMachinesLoaded({
    required this.subscribedMachineIds,
    required this.subscribedMachines,
    required this.claimedMachineMetadata,
    required this.claimedMachines,
  });

  @override
  List<Object?> get props => [
    subscribedMachineIds,
    subscribedMachines,
    claimedMachineMetadata,
    claimedMachines,
  ];
}

class MyMachinesRefreshing extends MyMachinesLoaded {
  const MyMachinesRefreshing({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required super.claimedMachines,
  });
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
  final MachineEntity operatingMachine;

  const MyMachinesSubscribing({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
    required super.claimedMachines,
  });
}

class MyMachinesSubscribed extends MyMachinesLoaded {
  final MachineEntity operatingMachine;

  const MyMachinesSubscribed({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
    required super.claimedMachines,
  });
  @override
  List<Object?> get props => [...super.props, operatingMachine];
}

class MyMachinesUnsubscribed extends MyMachinesLoaded {
  final MachineEntity operatingMachine;

  const MyMachinesUnsubscribed({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
    required super.claimedMachines,
  });
  @override
  List<Object?> get props => [...super.props, operatingMachine];
}

class MyMachinesSubscribeError extends MyMachinesLoaded {
  final MachineEntity operatingMachine;
  final String message;

  const MyMachinesSubscribeError({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
    required this.message,
    required super.claimedMachines,
  });

  @override
  List<Object?> get props => [...super.props, operatingMachine, message];
}

// This event will only happen after the machines have loaded.
// covers Subscribing and unclaiming states
class MyMachinesClaiming extends MyMachinesLoaded {
  final MachineEntity operatingMachine;
  const MyMachinesClaiming({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
    required super.claimedMachines,
  });
}

class MyMachinesClaimed extends MyMachinesLoaded {
  final MachineEntity operatingMachine;

  const MyMachinesClaimed({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
    required super.claimedMachines,
  });
  @override
  List<Object?> get props => [...super.props, operatingMachine];
}

class MyMachinesUnclaimed extends MyMachinesLoaded {
  final MachineEntity operatingMachine;

  const MyMachinesUnclaimed({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
    required super.claimedMachines,
  });
  @override
  List<Object?> get props => [...super.props, operatingMachine];
}

class MyMachinesErrorClaiming extends MyMachinesLoaded {
  final MachineEntity operatingMachine;
  final String message;

  const MyMachinesErrorClaiming({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.claimedMachineMetadata,
    required this.operatingMachine,
    required this.message,
    required super.claimedMachines,
  });

  @override
  List<Object?> get props => [...super.props, operatingMachine, message];
}
