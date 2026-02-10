import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

/// Base state for subscription management
abstract class SubscriptionState {
  final List<String> subscribedMachineIds;
  final List<MachineEntity>? subscribedMachines;
  final List<String> subscribedGroupKeys;
  final Map<String, List<MachineEntity>>? subscribedGroups;

  const SubscriptionState({
    required this.subscribedMachineIds,
    this.subscribedMachines,
    required this.subscribedGroupKeys,
    this.subscribedGroups,
  });
}

/// Initial state
class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial()
    : super(
        subscribedMachineIds: const [],
        subscribedGroupKeys: const [],
        subscribedGroups: const {},
      );
}

/// Loading subscribed machines
class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading({
    required super.subscribedMachineIds,
    super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
  });
}

/// Subscribed machines loaded successfully
class SubscriptionLoaded extends SubscriptionState {
  const SubscriptionLoaded({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
  });
}

/// Refreshing subscribed machines list
class SubscriptionRefreshing extends SubscriptionLoaded {
  const SubscriptionRefreshing({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
  });
}

/// Currently subscribing to a machine
class Subscribing extends SubscriptionLoaded {
  final MachineEntity operatingMachine;

  const Subscribing({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
    required this.operatingMachine,
  });
}

/// Successfully subscribed to a machine
class Subscribed extends SubscriptionLoaded {
  final MachineEntity operatingMachine;

  const Subscribed({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
    required this.operatingMachine,
  });
}

/// Successfully unsubscribed from a machine
class Unsubscribed extends SubscriptionLoaded {
  final MachineEntity operatingMachine;

  const Unsubscribed({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
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
    required super.subscribedGroupKeys,
    super.subscribedGroups,
    required this.message,
    required this.operatingMachine,
  });
}

/// Error loading subscribed machines
class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError({required this.message})
    : super(
        subscribedMachineIds: const [],
        subscribedGroupKeys: const [],
        subscribedGroups: const {},
      );
}

/// Currently subscribing to a group
class SubscribingToGroup extends SubscriptionLoaded {
  final String operatingGroupKey;

  const SubscribingToGroup({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
    required this.operatingGroupKey,
  });
}

/// Successfully subscribed to a group
class SubscribedToGroup extends SubscriptionLoaded {
  final String operatingGroupKey;

  const SubscribedToGroup({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
    required this.operatingGroupKey,
  });
}

/// Successfully unsubscribed from a group
class UnsubscribedFromGroup extends SubscriptionLoaded {
  final String operatingGroupKey;

  const UnsubscribedFromGroup({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
    required this.operatingGroupKey,
  });
}

/// Error subscribing/unsubscribing from group
class SubscriptionGroupOperationError extends SubscriptionLoaded {
  final String message;
  final String operatingGroupKey;

  const SubscriptionGroupOperationError({
    required super.subscribedMachineIds,
    required super.subscribedMachines,
    required super.subscribedGroupKeys,
    super.subscribedGroups,
    required this.message,
    required this.operatingGroupKey,
  });
}
