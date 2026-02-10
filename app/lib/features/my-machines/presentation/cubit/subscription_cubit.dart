import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/firebase_notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/subscription_utils.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'subscription_state.dart';

/// Cubit for managing machine subscriptions
///
/// This cubit handles:
/// - Loading subscribed machine IDs from local storage
/// - Fetching actual machine data from repository
/// - Subscribing to new machines (both notification topic and local storage)
/// - Unsubscribing from machines (both notification topic and local storage)
class SubscriptionCubit extends Cubit<SubscriptionState> {
  final SharedPreferencesService _sharedPreferencesService;
  final FirebaseNotificationService _notificationService;
  final ListMachinesUseCase _listMachinesUseCase;

  SubscriptionCubit({
    required SharedPreferencesService sharedPreferencesService,
    required FirebaseNotificationService notificationService,
    required ListMachinesUseCase listMachinesUseCase,
  }) : _sharedPreferencesService = sharedPreferencesService,
       _notificationService = notificationService,
       _listMachinesUseCase = listMachinesUseCase,
       super(const SubscriptionInitial());

  /// Load subscribed machines from local storage and fetch their data
  Future<List<MachineEntity>> _getSubscribedMachines() async {
    final subscribedMachineIds = _sharedPreferencesService
        .getSubscribedMachines();

    if (subscribedMachineIds.isEmpty) {
      return <MachineEntity>[];
    }

    appLog.d(
      'Loading ${subscribedMachineIds.length} subscribed machines from repository',
    );

    // Fetch machines from repository
    final result = await _listMachinesUseCase(
      ListMachinesParams(machineIds: subscribedMachineIds, extra: true),
    );

    return result.fold(
      (failure) {
        appLog.e('Error loading machines: ${failure.message}');
        throw Failure(message: failure.message);
      },
      (machines) {
        appLog.i('Successfully loaded ${machines.length} subscribed machines');
        return machines;
      },
    );
  }

  /// Load subscribed groups from local storage and fetch their data
  Future<Map<String, List<MachineEntity>>> _getSubscribedGroups() async {
    final subscribedGroupKeys = _sharedPreferencesService.getSubscribedGroups();

    if (subscribedGroupKeys.isEmpty) {
      return {};
    }

    appLog.d(
      'Loading ${subscribedGroupKeys.length} subscribed groups from repository',
    );

    // groupKey format: group_roomId_type (e.g., "group_3_washer")
    // Using groupKey directly as map key for simplicity
    Map<String, List<MachineEntity>> groupMachines = {};

    for (final groupKey in subscribedGroupKeys) {
      final parts = groupKey.split('_');
      if (parts.length != 3) {
        appLog.w('Invalid group key format: $groupKey');
        continue;
      }

      final roomId = parts[1];
      final typeString = parts[2];
      final type = MachineType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () {
          appLog.w('Unknown machine type in group key: $groupKey');
          return MachineType.unknown;
        },
      );

      appLog.d('Fetching machines for group: roomId=$roomId, type=$type');

      // Fetch machines from repository
      final result = await _listMachinesUseCase(
        ListMachinesParams(roomIds: [roomId], types: [type.name], extra: true),
      );

      result.fold(
        (failure) {
          appLog.e(
            'Error loading machines for group $groupKey: ${failure.message}',
          );
        },
        (machines) {
          appLog.i(
            'Successfully loaded ${machines.length} machines for group $groupKey',
          );
          groupMachines[groupKey] = machines;
        },
      );
    }

    return groupMachines;
  }

  /// Load all subscribed machines
  Future<void> loadSubscribedEntities() async {
    try {
      emit(
        SubscriptionLoading(
          subscribedMachineIds: _sharedPreferencesService
              .getSubscribedMachines(),
          subscribedGroupKeys: _sharedPreferencesService.getSubscribedGroups(),
        ),
      );

      try {
        final subscribedMachines = await _getSubscribedMachines();
        final subscribedGroups = await _getSubscribedGroups();
        final subscribedMachineIds = _sharedPreferencesService
            .getSubscribedMachines();
        final subscribedGroupKeys = _sharedPreferencesService
            .getSubscribedGroups();

        emit(
          SubscriptionLoaded(
            subscribedMachineIds: subscribedMachineIds,
            subscribedMachines: subscribedMachines,
            subscribedGroupKeys: subscribedGroupKeys,
            subscribedGroups: subscribedGroups,
          ),
        );
      } catch (e) {
        appLog.e('Error loading subscribed entities: $e');
        emit(
          const SubscriptionError(
            message: 'Failed to load subscribed machines',
          ),
        );
      }
    } catch (e) {
      appLog.e('Error loading subscribed machines: $e');
      emit(
        const SubscriptionError(message: 'Failed to load subscribed machines'),
      );
    }
  }

  /// Refresh subscribed machines list
  Future<void> refreshSubscribedMachines() async {
    final currentState = state;
    if (currentState is SubscriptionLoaded) {
      try {
        emit(
          SubscriptionRefreshing(
            subscribedMachineIds: currentState.subscribedMachineIds,
            subscribedMachines: currentState.subscribedMachines,
            subscribedGroupKeys: currentState.subscribedGroupKeys,
            subscribedGroups: currentState.subscribedGroups,
          ),
        );

        final subscribedMachines = await _getSubscribedMachines();
        final subscribedGroups = await _getSubscribedGroups();
        final subscribedMachineIds = _sharedPreferencesService
            .getSubscribedMachines();
        final subscribedGroupKeys = _sharedPreferencesService
            .getSubscribedGroups();

        emit(
          SubscriptionLoaded(
            subscribedMachineIds: subscribedMachineIds,
            subscribedMachines: subscribedMachines,
            subscribedGroupKeys: subscribedGroupKeys,
            subscribedGroups: subscribedGroups,
          ),
        );
      } catch (e) {
        appLog.e('Error refreshing subscribed machines: $e');
        // Keep current state on error
      }
    }
  }

  /// Subscribe to a machine
  /// - Subscribes to FCM topic via NotificationService
  /// - Saves to local storage via SharedPreferencesService
  /// NOTE: does NOT hit the backend.
  Future<void> subscribeToMachine(MachineEntity machine) async {
    final machineId = machine.machineId;
    final currentState = state;

    List<String> currentMachineIds = [];
    List<MachineEntity>? currentMachines;
    List<String> currentGroupKeys = [];
    Map<String, List<MachineEntity>>? currentGroups;

    if (currentState is SubscriptionLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentMachines = currentState.subscribedMachines;
      currentGroupKeys = currentState.subscribedGroupKeys;
      currentGroups = currentState.subscribedGroups;
    }

    try {
      emit(
        Subscribing(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingMachine: machine,
        ),
      );

      if (currentMachineIds.contains(machineId)) {
        appLog.w('Already subscribed to machine: $machineId');
        return;
      }

      // Subscribe to notification topic
      await _notificationService.subscribeToMachine(machineId);

      // Reload from shared preferences to get updated list
      final updatedMachineIds = _sharedPreferencesService
          .getSubscribedMachines();
      final updatedGroupKeys = _sharedPreferencesService.getSubscribedGroups();

      appLog.i('Successfully subscribed to machine: $machineId');

      emit(
        Subscribed(
          subscribedMachineIds: updatedMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: updatedGroupKeys,
          subscribedGroups: currentGroups,
          operatingMachine: machine,
        ),
      );

      // Wait a bit, then reload machines
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (isClosed) return;
        try {
          final subscribedMachines = await _getSubscribedMachines();
          final subscribedGroups = await _getSubscribedGroups();
          final subscribedMachineIds = _sharedPreferencesService
              .getSubscribedMachines();
          final subscribedGroupKeys = _sharedPreferencesService
              .getSubscribedGroups();

          if (!isClosed) {
            emit(
              SubscriptionLoaded(
                subscribedMachineIds: subscribedMachineIds,
                subscribedMachines: subscribedMachines,
                subscribedGroupKeys: subscribedGroupKeys,
                subscribedGroups: subscribedGroups,
              ),
            );
          }
        } catch (e) {
          appLog.e('Error loading machines after subscription: $e');
          if (!isClosed) {
            emit(const SubscriptionError(message: 'Failed to load machines'));
          }
        }
      });
    } catch (e) {
      appLog.e('Error subscribing to machine $machineId: $e');
      emit(
        SubscriptionOperationError(
          message: 'Failed to subscribe to machine',
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingMachine: machine,
        ),
      );

      // Reload current state after error
      loadSubscribedEntities();
    }
  }

  /// Unsubscribe from a machine
  /// - Unsubscribes from FCM topic via NotificationService
  /// - Removes from local storage via SharedPreferencesService
  /// NOTE: does NOT hit the backend.
  Future<void> unsubscribeFromMachine(MachineEntity machine) async {
    final machineId = machine.machineId;
    final currentState = state;

    List<String> currentMachineIds = [];
    List<MachineEntity>? currentMachines;
    List<String> currentGroupKeys = [];
    Map<String, List<MachineEntity>>? currentGroups;

    if (currentState is SubscriptionLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentMachines = currentState.subscribedMachines;
      currentGroupKeys = currentState.subscribedGroupKeys;
      currentGroups = currentState.subscribedGroups;
    }

    try {
      // Check if not subscribed
      if (!currentMachineIds.contains(machineId)) {
        appLog.w('Not subscribed to machine: $machineId');
        return;
      }

      emit(
        Subscribing(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingMachine: machine,
        ),
      );

      // Unsubscribe from notification topic
      await _notificationService.unsubscribeFromMachine(machineId);

      // Reload from shared preferences to get updated list
      final updatedMachineIds = _sharedPreferencesService
          .getSubscribedMachines();
      final updatedGroupKeys = _sharedPreferencesService.getSubscribedGroups();

      appLog.i('Successfully unsubscribed from machine: $machineId');

      emit(
        Unsubscribed(
          subscribedMachineIds: updatedMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: updatedGroupKeys,
          subscribedGroups: currentGroups,
          operatingMachine: machine,
        ),
      );

      // Wait a bit, then update machines list
      Future.delayed(const Duration(seconds: 1), () {
        if (!isClosed) {
          emit(
            SubscriptionLoaded(
              subscribedMachineIds: updatedMachineIds,
              subscribedMachines: currentMachines
                  ?.where((m) => m.machineId != machineId)
                  .toList(),
              subscribedGroupKeys: updatedGroupKeys,
              subscribedGroups: currentGroups,
            ),
          );
        }
      });
    } catch (e) {
      appLog.e('Error unsubscribing from machine $machineId: $e');
      emit(
        SubscriptionOperationError(
          message: 'Failed to unsubscribe from machine',
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingMachine: machine,
        ),
      );

      // Reload current state after error
      loadSubscribedEntities();
    }
  }

  /// Check if subscribed to a specific machine
  bool isSubscribedToMachine(String machineId) {
    return _sharedPreferencesService.isSubscribedToMachine(machineId);
  }

  /// Get count of subscribed machines
  int getSubscribedMachinesCount() {
    final currentState = state;
    if (currentState is SubscriptionLoaded) {
      return currentState.subscribedMachineIds.length;
    }
    return 0;
  }

  /// Subscribe to a group (e.g., all washers in a room)
  /// - Subscribes to FCM topic via NotificationService
  /// - Saves to local storage via SharedPreferencesService
  /// NOTE: does NOT hit the backend.
  Future<void> subscribeToGroup(String groupKey) async {
    final currentState = state;

    List<String> currentMachineIds = [];
    List<MachineEntity>? currentMachines;
    List<String> currentGroupKeys = [];
    Map<String, List<MachineEntity>>? currentGroups;

    if (currentState is SubscriptionLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentMachines = currentState.subscribedMachines;
      currentGroupKeys = currentState.subscribedGroupKeys;
      currentGroups = currentState.subscribedGroups;
    }

    try {
      emit(
        SubscribingToGroup(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingGroupKey: groupKey,
        ),
      );

      if (currentGroupKeys.contains(groupKey)) {
        appLog.w('Already subscribed to group: $groupKey');
        return;
      }

      // Subscribe to notification topic
      await _notificationService.subscribeToGroup(groupKey);

      // Reload from shared preferences to get updated list
      final updatedGroupKeys = _sharedPreferencesService.getSubscribedGroups();
      final updatedGroups = await _getSubscribedGroups();

      appLog.i('Successfully subscribed to group: $groupKey');

      emit(
        SubscribedToGroup(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: updatedGroupKeys,
          subscribedGroups: updatedGroups,
          operatingGroupKey: groupKey,
        ),
      );

      // Wait a bit, then emit loaded state
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) {
          emit(
            SubscriptionLoaded(
              subscribedMachineIds: currentMachineIds,
              subscribedMachines: currentMachines,
              subscribedGroupKeys: updatedGroupKeys,
              subscribedGroups: updatedGroups,
            ),
          );
        }
      });
    } catch (e) {
      appLog.e('Error subscribing to group $groupKey: $e');
      emit(
        SubscriptionGroupOperationError(
          message: 'Failed to subscribe to group',
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingGroupKey: groupKey,
        ),
      );

      // Reload current state after error
      loadSubscribedEntities();
    }
  }

  /// Unsubscribe from a group
  /// - Unsubscribes from FCM topic via NotificationService
  /// - Removes from local storage via SharedPreferencesService
  /// NOTE: does NOT hit the backend.
  Future<void> unsubscribeFromGroup(String groupKey) async {
    final currentState = state;

    List<String> currentMachineIds = [];
    List<MachineEntity>? currentMachines;
    List<String> currentGroupKeys = [];
    Map<String, List<MachineEntity>>? currentGroups;

    if (currentState is SubscriptionLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentMachines = currentState.subscribedMachines;
      currentGroupKeys = currentState.subscribedGroupKeys;
      currentGroups = currentState.subscribedGroups;
    }

    try {
      if (!currentGroupKeys.contains(groupKey)) {
        appLog.w('Not subscribed to group: $groupKey');
        return;
      }

      emit(
        SubscribingToGroup(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingGroupKey: groupKey,
        ),
      );

      // Unsubscribe from notification topic
      await _notificationService.unsubscribeFromGroup(groupKey);

      // Reload from shared preferences to get updated list
      final updatedGroupKeys = _sharedPreferencesService.getSubscribedGroups();
      final updatedGroups = await _getSubscribedGroups();

      appLog.i('Successfully unsubscribed from group: $groupKey');

      emit(
        UnsubscribedFromGroup(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: updatedGroupKeys,
          subscribedGroups: updatedGroups,
          operatingGroupKey: groupKey,
        ),
      );

      // Wait a bit, then emit loaded state
      Future.delayed(const Duration(seconds: 1), () {
        if (!isClosed) {
          emit(
            SubscriptionLoaded(
              subscribedMachineIds: currentMachineIds,
              subscribedMachines: currentMachines,
              subscribedGroupKeys: updatedGroupKeys,
              subscribedGroups: updatedGroups,
            ),
          );
        }
      });
    } catch (e) {
      appLog.e('Error unsubscribing from group $groupKey: $e');
      emit(
        SubscriptionGroupOperationError(
          message: 'Failed to unsubscribe from group',
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingGroupKey: groupKey,
        ),
      );

      // Reload current state after error
      loadSubscribedEntities();
    }
  }

  /// Check if subscribed to a specific group
  bool isSubscribedToGroup(String groupKey) {
    return _sharedPreferencesService.isSubscribedToGroup(groupKey);
  }

  /// Check if subscribed to all groups in a list
  bool isSubscribedToGroups(List<String> groupKeys) {
    return groupKeys.every(
      (key) => _sharedPreferencesService.isSubscribedToGroup(key),
    );
  }

  /// Subscribe to multiple groups
  /// - Subscribes to FCM topics via NotificationService
  /// - Saves to local storage via SharedPreferencesService
  /// NOTE: does NOT hit the backend.
  Future<void> subscribeToGroups(List<String> groupKeys) async {
    final currentState = state;

    List<String> currentMachineIds = [];
    List<MachineEntity>? currentMachines;
    List<String> currentGroupKeys = [];
    Map<String, List<MachineEntity>>? currentGroups;

    if (currentState is SubscriptionLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentMachines = currentState.subscribedMachines;
      currentGroupKeys = currentState.subscribedGroupKeys;
      currentGroups = currentState.subscribedGroups;
    }

    // Filter out already subscribed groups
    final groupsToSubscribe = groupKeys
        .where((key) => !currentGroupKeys.contains(key))
        .toList();
    try {
      if (groupsToSubscribe.isEmpty) {
        appLog.w('Already subscribed to all groups: $groupKeys');
        return;
      }

      // Subscribe to each group
      for (final groupKey in groupsToSubscribe) {
        await _notificationService.subscribeToGroup(groupKey);
        appLog.i('Successfully subscribed to group: $groupKey');
      }

      // Reload from shared preferences to get updated list
      final updatedGroupKeys = _sharedPreferencesService.getSubscribedGroups();
      final updatedGroups = await _getSubscribedGroups();

      emit(
        SubscriptionLoaded(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: updatedGroupKeys,
          subscribedGroups: updatedGroups,
        ),
      );
    } catch (e) {
      appLog.e('Error subscribing to groups $groupKeys: $e');

      // remove from pref
      for (final groupKey in groupsToSubscribe) {
        _sharedPreferencesService.unsubscribeFromGroups({groupKey});
      }
      emit(
        SubscriptionGroupOperationError(
          message: 'Failed to subscribe to groups',
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingGroupKey: groupKeys.join(', '),
        ),
      );

      // Reload current state after error
    } finally {
      loadSubscribedEntities();
    }
  }

  /// Unsubscribe from multiple groups
  /// - Unsubscribes from FCM topics via NotificationService
  /// - Removes from local storage via SharedPreferencesService
  /// NOTE: does NOT hit the backend.
  Future<void> unsubscribeFromGroups(List<String> groupKeys) async {
    final currentState = state;

    List<String> currentMachineIds = [];
    List<MachineEntity>? currentMachines;
    List<String> currentGroupKeys = [];
    Map<String, List<MachineEntity>>? currentGroups;

    if (currentState is SubscriptionLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentMachines = currentState.subscribedMachines;
      currentGroupKeys = currentState.subscribedGroupKeys;
      currentGroups = currentState.subscribedGroups;
    }

    try {
      // Filter out groups not subscribed to
      final groupsToUnsubscribe = groupKeys
          .where((key) => currentGroupKeys.contains(key))
          .toList();

      if (groupsToUnsubscribe.isEmpty) {
        appLog.w('Not subscribed to any of the groups: $groupKeys');
        return;
      }

      // Unsubscribe from each group
      for (final groupKey in groupsToUnsubscribe) {
        await _notificationService.unsubscribeFromGroup(groupKey);
        appLog.i('Successfully unsubscribed from group: $groupKey');
      }

      // Reload from shared preferences to get updated list
      final updatedGroupKeys = _sharedPreferencesService.getSubscribedGroups();
      final updatedGroups = await _getSubscribedGroups();

      emit(
        SubscriptionLoaded(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: updatedGroupKeys,
          subscribedGroups: updatedGroups,
        ),
      );
    } catch (e) {
      appLog.e('Error unsubscribing from groups $groupKeys: $e');
      emit(
        SubscriptionGroupOperationError(
          message: 'Failed to unsubscribe from groups',
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          subscribedGroupKeys: currentGroupKeys,
          subscribedGroups: currentGroups,
          operatingGroupKey: groupKeys.join(', '),
        ),
      );
    } finally {
      loadSubscribedEntities();
    }
  }

  /// Get all subscribed group keys
  List<String> getSubscribedGroups() {
    return _sharedPreferencesService.getSubscribedGroups();
  }

  /// Get count of subscribed groups
  int getSubscribedGroupsCount() {
    return _sharedPreferencesService.getSubscribedGroups().length;
  }
}
