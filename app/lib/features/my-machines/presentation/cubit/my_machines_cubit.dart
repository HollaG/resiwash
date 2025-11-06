import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'my_machines_state.dart';

/// Cubit for managing user's subscribed machines
///
/// This cubit handles:
/// - Loading subscribed machine IDs from local storage
/// - Fetching actual machine data from repository
/// - Subscribing to new machines (both notification topic and local storage)
/// - Unsubscribing from machines (both notification topic and local storage)
/// - Deleting/removing a single machine subscription
class MyMachinesCubit extends Cubit<MyMachinesState> {
  final SharedPreferencesService _sharedPreferencesService;
  final NotificationService _notificationService;
  final ListMachinesUseCase _listMachinesUseCase;

  MyMachinesCubit({
    required SharedPreferencesService sharedPreferencesService,
    required NotificationService notificationService,
    required ListMachinesUseCase listMachinesUseCase,
  }) : _sharedPreferencesService = sharedPreferencesService,
       _notificationService = notificationService,
       _listMachinesUseCase = listMachinesUseCase,
       super(MyMachinesInitial());

  /// Load full machine data from repository for subscribed machines
  /// This fetches the complete machine entities from the API
  Future<void> loadNotifyableMachines() async {
    try {
      emit(MyMachinesLoading());

      // Get subscribed machine IDs from local storage
      final subscribedMachineIds = _sharedPreferencesService
          .getSubscribedMachines();

      final claimedMachineMetadata = _sharedPreferencesService
          .getClaimedMachines();

      appLog.d(
        'Loading ${subscribedMachineIds.length} subscribed machines from repository',
      );

      if (subscribedMachineIds.isEmpty) {
        emit(
          MyMachinesLoaded(
            subscribedMachineIds: [],
            machines: [],
            claimedMachineMetadata: [],
          ),
        );
        return;
      }

      // Fetch machines from repository
      final result = await _listMachinesUseCase(
        ListMachinesParams(machineIds: subscribedMachineIds, extra: true),
      );

      result.fold(
        (failure) {
          appLog.e('Error loading machines: ${failure.message}');
          emit(MyMachinesError(message: 'Failed to load machines'));
        },
        (machines) {
          appLog.i('Successfully loaded ${machines.length} machines');
          emit(
            MyMachinesLoaded(
              subscribedMachineIds: subscribedMachineIds,
              machines: machines,
              claimedMachineMetadata: claimedMachineMetadata,
            ),
          );
        },
      );
    } catch (e) {
      appLog.e('Error loading subscribed machines: $e');
      emit(MyMachinesError(message: 'Failed to load subscribed machines'));
    }
  }

  /// Subscribe to a machine
  /// - Subscribes to FCM topic via NotificationService
  /// - Saves to local storage via SharedPreferencesService
  Future<void> subscribeToMachine(String machineId) async {
    try {
      final currentState = state;
      List<String> currentMachines = [];
      List<ClaimedMachineMetadata> currentClaimedMachines = [];

      if (currentState is MyMachinesLoaded) {
        currentMachines = currentState.subscribedMachineIds;
        currentClaimedMachines = currentState.claimedMachineMetadata;
      } else if (currentState is MyMachinesOperationInProgress) {
        currentMachines = currentState.subscribedMachineIds;
      }

      // Check if already subscribed
      if (currentMachines.contains(machineId)) {
        appLog.w('Already subscribed to machine: $machineId');
        return;
      }

      emit(
        MyMachinesOperationInProgress(
          subscribedMachineIds: currentMachines,
          operatingMachineId: machineId,
        ),
      );

      // Subscribe to notification topic
      await _notificationService.subscribeToMachine(machineId);

      // Reload from shared preferences to get updated list
      final updatedMachines = _sharedPreferencesService.getSubscribedMachines();

      appLog.i('Successfully subscribed to machine: $machineId');

      emit(
        MyMachinesLoaded(
          subscribedMachineIds: updatedMachines,
          machines: currentState is MyMachinesLoaded
              ? currentState.machines
              : null,
          claimedMachineMetadata: currentClaimedMachines,
        ),
      );
    } catch (e) {
      appLog.e('Error subscribing to machine $machineId: $e');
      emit(MyMachinesError(message: 'Failed to subscribe to machine'));

      // Reload current state after error
      loadNotifyableMachines();
    }
  }

  /// Unsubscribe from a machine
  /// - Unsubscribes from FCM topic via NotificationService
  /// - Removes from local storage via SharedPreferencesService
  Future<void> unsubscribeFromMachine(String machineId) async {
    try {
      final currentState = state;
      List<String> currentMachines = [];

      if (currentState is MyMachinesLoaded) {
        currentMachines = currentState.subscribedMachineIds;
      } else if (currentState is MyMachinesOperationInProgress) {
        currentMachines = currentState.subscribedMachineIds;
      }

      // Check if not subscribed
      if (!currentMachines.contains(machineId)) {
        appLog.w('Not subscribed to machine: $machineId');
        return;
      }

      emit(
        MyMachinesOperationInProgress(
          subscribedMachineIds: currentMachines,
          operatingMachineId: machineId,
        ),
      );

      // Unsubscribe from notification topic
      await _notificationService.unsubscribeFromMachine(machineId);

      // Reload from shared preferences to get updated list
      final updatedMachines = _sharedPreferencesService.getSubscribedMachines();

      // unclaim the machine
      _sharedPreferencesService.unclaimMachine(machineId);
      List<ClaimedMachineMetadata> currentClaimedMachines =
          _sharedPreferencesService.getClaimedMachines();

      appLog.i('Successfully unsubscribed from machine: $machineId');

      emit(
        MyMachinesLoaded(
          subscribedMachineIds: updatedMachines,
          claimedMachineMetadata: currentClaimedMachines,
        ),
      );
    } catch (e) {
      appLog.e('Error unsubscribing from machine $machineId: $e');
      emit(MyMachinesError(message: 'Failed to unsubscribe from machine'));

      // Reload current state after error
      loadNotifyableMachines();
    }
  }

  /// Delete a machine subscription (alias for unsubscribeFromMachine)
  /// This provides a more semantic method name for removing machines
  Future<void> deleteMachineSubscription(String machineId) async {
    await unsubscribeFromMachine(machineId);
  }

  /// Batch subscribe to multiple machines
  Future<void> subscribeToMachines(List<String> machineIds) async {
    for (final machineId in machineIds) {
      await subscribeToMachine(machineId);
    }
  }

  /// Batch unsubscribe from multiple machines
  Future<void> unsubscribeFromMachines(List<String> machineIds) async {
    for (final machineId in machineIds) {
      await unsubscribeFromMachine(machineId);
    }
  }

  /// Check if subscribed to a specific machine
  bool isSubscribedToMachine(String machineId) {
    return _sharedPreferencesService.isSubscribedToMachine(machineId);
  }

  /// Get count of subscribed machines
  int getSubscribedMachinesCount() {
    final state = this.state;
    if (state is MyMachinesLoaded) {
      return state.subscribedMachineIds.length;
    } else if (state is MyMachinesOperationInProgress) {
      return state.subscribedMachineIds.length;
    }
    return 0;
  }

  /// Claim a machine (mark as "in use by you")
  void claimMachine(String machineId, {int? cycleTime}) {
    try {
      // Add to SharedPreferences with optional cycle time
      _sharedPreferencesService.claimMachine(machineId, cycleTime: cycleTime);

      // Reload state to reflect changes
      final currentState = state;
      if (currentState is MyMachinesLoaded) {
        final updatedClaimedMetadata = _sharedPreferencesService
            .getClaimedMachines();
        emit(
          MyMachinesLoaded(
            subscribedMachineIds: currentState.subscribedMachineIds,
            machines: currentState.machines,
            claimedMachineMetadata: updatedClaimedMetadata,
          ),
        );
      }

      appLog.i('Claimed machine: $machineId with cycleTime: $cycleTime');
    } catch (e) {
      appLog.e('Error claiming machine $machineId: $e');
    }
  }

  /// Unclaim a machine (remove from "in use by you")
  void unclaimMachine(String machineId) {
    try {
      // Remove from SharedPreferences
      _sharedPreferencesService.unclaimMachine(machineId);

      // Reload state to reflect changes
      final currentState = state;
      if (currentState is MyMachinesLoaded) {
        final updatedClaimedMetadata = _sharedPreferencesService
            .getClaimedMachines();
        emit(
          MyMachinesLoaded(
            subscribedMachineIds: currentState.subscribedMachineIds,
            machines: currentState.machines,
            claimedMachineMetadata: updatedClaimedMetadata,
          ),
        );
      }

      appLog.i('Unclaimed machine: $machineId');
    } catch (e) {
      appLog.e('Error unclaiming machine $machineId: $e');
    }
  }

  /// Update the cycle time for a claimed machine
  void updateClaimedMachineCycleTime(String machineId, int? cycleTime) {
    try {
      _sharedPreferencesService.updateClaimedMachineCycleTime(
        machineId,
        cycleTime,
      );

      // State doesn't change for this operation (IDs remain the same)
      appLog.i('Updated cycle time for machine: $machineId to $cycleTime');
    } catch (e) {
      appLog.e('Error updating cycle time for machine $machineId: $e');
    }
  }
}
