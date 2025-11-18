import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

/// Base state for subscription management
abstract class SubscriptionState {
  final List<String> subscribedMachineIds;
  final List<MachineEntity>? subscribedMachines;

  const SubscriptionState({
    required this.subscribedMachineIds,
    this.subscribedMachines,
  });
}

/// Initial state
class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial() : super(subscribedMachineIds: const []);
}

/// Loading subscribed machines
class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading({
    required super.subscribedMachineIds,
    super.subscribedMachines,
  });
}

/// Subscribed machines loaded successfully
class SubscriptionLoaded extends SubscriptionState {
  const SubscriptionLoaded({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
  });
}

/// Refreshing subscribed machines list
class SubscriptionRefreshing extends SubscriptionLoaded {
  const SubscriptionRefreshing({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
  });
}

/// Currently subscribing to a machine
class Subscribing extends SubscriptionLoaded {
  final MachineEntity operatingMachine;

  const Subscribing({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required this.operatingMachine,
  });
}

/// Successfully subscribed to a machine
class Subscribed extends SubscriptionLoaded {
  final MachineEntity operatingMachine;

  const Subscribed({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required this.operatingMachine,
  });
}

/// Successfully unsubscribed from a machine
class Unsubscribed extends SubscriptionLoaded {
  final MachineEntity operatingMachine;

  const Unsubscribed({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required this.operatingMachine,
  });
}

/// Error subscribing/unsubscribing
class SubscriptionOperationError extends SubscriptionLoaded {
  final String message;
  final MachineEntity operatingMachine;

  const SubscriptionOperationError({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required this.message,
    required this.operatingMachine,
  });
}

/// Error loading subscribed machines
class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError({required this.message})
    : super(subscribedMachineIds: const []);
}
