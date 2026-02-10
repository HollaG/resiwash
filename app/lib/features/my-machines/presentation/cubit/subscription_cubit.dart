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

  /// Load all subscribed machines
  Future<void> loadSubscribedMachines() async {
    try {
      emit(
        SubscriptionLoading(
          subscribedMachineIds: _sharedPreferencesService
              .getSubscribedMachines(),
        ),
      );

      try {
        final subscribedMachines = await _getSubscribedMachines();
        final subscribedMachineIds = _sharedPreferencesService
            .getSubscribedMachines();

        emit(
          SubscriptionLoaded(
            subscribedMachineIds: subscribedMachineIds,
            subscribedMachines: subscribedMachines,
          ),
        );
      } catch (e) {
        appLog.e('Error loading subscribed machines: $e');
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
          ),
        );

        final subscribedMachines = await _getSubscribedMachines();
        final subscribedMachineIds = _sharedPreferencesService
            .getSubscribedMachines();

        emit(
          SubscriptionLoaded(
            subscribedMachineIds: subscribedMachineIds,
            subscribedMachines: subscribedMachines,
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

    if (currentState is SubscriptionLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentMachines = currentState.subscribedMachines;
    }

    try {
      emit(
        Subscribing(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
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

      appLog.i('Successfully subscribed to machine: $machineId');

      emit(
        Subscribed(
          subscribedMachineIds: updatedMachineIds,
          subscribedMachines: currentMachines,
          operatingMachine: machine,
        ),
      );

      // Wait a bit, then reload machines
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (isClosed) return;
        try {
          final subscribedMachines = await _getSubscribedMachines();
          final subscribedMachineIds = _sharedPreferencesService
              .getSubscribedMachines();

          if (!isClosed) {
            emit(
              SubscriptionLoaded(
                subscribedMachineIds: subscribedMachineIds,
                subscribedMachines: subscribedMachines,
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
          operatingMachine: machine,
        ),
      );

      // Reload current state after error
      loadSubscribedMachines();
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

    if (currentState is SubscriptionLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentMachines = currentState.subscribedMachines;
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
          operatingMachine: machine,
        ),
      );

      // Unsubscribe from notification topic
      await _notificationService.unsubscribeFromMachine(machineId);

      // Reload from shared preferences to get updated list
      final updatedMachineIds = _sharedPreferencesService
          .getSubscribedMachines();

      appLog.i('Successfully unsubscribed from machine: $machineId');

      emit(
        Unsubscribed(
          subscribedMachineIds: updatedMachineIds,
          subscribedMachines: currentMachines,
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
          operatingMachine: machine,
        ),
      );

      // Reload current state after error
      loadSubscribedMachines();
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
    final currentGroupKeys = _sharedPreferencesService.getSubscribedGroups();

    try {
      if (currentGroupKeys.contains(groupKey)) {
        appLog.w('Already subscribed to group: $groupKey');
        return;
      }

      // Subscribe to notification topic
      await _notificationService.subscribeToGroup(groupKey);

      appLog.i('Successfully subscribed to group: $groupKey');
    } catch (e) {
      appLog.e('Error subscribing to group $groupKey: $e');
      rethrow;
    }
  }

  /// Unsubscribe from a group
  /// - Unsubscribes from FCM topic via NotificationService
  /// - Removes from local storage via SharedPreferencesService
  /// NOTE: does NOT hit the backend.
  Future<void> unsubscribeFromGroup(String groupKey) async {
    final currentGroupKeys = _sharedPreferencesService.getSubscribedGroups();

    try {
      if (!currentGroupKeys.contains(groupKey)) {
        appLog.w('Not subscribed to group: $groupKey');
        return;
      }

      // Unsubscribe from notification topic
      await _notificationService.unsubscribeFromGroup(groupKey);

      appLog.i('Successfully unsubscribed from group: $groupKey');
    } catch (e) {
      appLog.e('Error unsubscribing from group $groupKey: $e');
      rethrow;
    }
  }

  /// Check if subscribed to a specific group
  bool isSubscribedToGroup(String groupKey) {
    return _sharedPreferencesService.isSubscribedToGroup(groupKey);
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
