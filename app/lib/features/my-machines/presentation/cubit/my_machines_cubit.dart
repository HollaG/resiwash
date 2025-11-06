import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
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

  /// INIT METHOD
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
  Future<void> subscribeToMachine(MachineEntity machine) async {
    final machineId = machine.machineId;
    try {
      final currentState = state;
      List<String> currentMachineIds = [];
      List<ClaimedMachineMetadata> currentClaimedMachines = [];
      List<MachineEntity> currentMachines = [];

      if (currentState is MyMachinesLoaded) {
        currentMachineIds = currentState.subscribedMachineIds;
        currentClaimedMachines = currentState.claimedMachineMetadata;
        currentMachines = currentState.machines ?? [];
      }

      emit(
        MyMachinesSubscribing(
          subscribedMachineIds: currentMachineIds,
          machines: currentState is MyMachinesLoaded
              ? currentState.machines
              : null,
          claimedMachineMetadata: currentClaimedMachines,
        ),
      );

      if (currentMachineIds.contains(machineId)) {
        appLog.w('Already subscribed to machine: $machineId');
        return;
      }

      // Subscribe to notification topic
      await _notificationService.subscribeToMachine(machineId);

      // Reload from shared preferences to get updated list
      final updatedMachines = _sharedPreferencesService.getSubscribedMachines();

      // refresh the claimed machines list

      appLog.i('Successfully subscribed to machine: $machineId');

      emit(
        MyMachinesSubscribed(
          subscribedMachineIds: updatedMachines,
          machines: currentState is MyMachinesLoaded
              ? currentState.machines
              : null,
          claimedMachineMetadata: currentClaimedMachines,
          operatingMachine: machine,
        ),
      );

      // wait for 1s, then emit
      Future.delayed(const Duration(milliseconds: 500), () async {
        // Fetch machines from repository
        final result = await _listMachinesUseCase(
          ListMachinesParams(machineIds: updatedMachines, extra: true),
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
                subscribedMachineIds: updatedMachines,
                machines: machines,
                claimedMachineMetadata: currentState is MyMachinesLoaded
                    ? currentState.claimedMachineMetadata
                    : [],
              ),
            );
          },
        );
      });
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
  Future<void> unsubscribeFromMachine(MachineEntity machine) async {
    final machineId = machine.machineId;
    try {
      final currentState = state;
      List<String> currentMachineIds = [];
      List<ClaimedMachineMetadata> currentClaimedMachines = [];
      List<MachineEntity> currentMachines = [];

      if (currentState is MyMachinesLoaded) {
        currentMachineIds = currentState.subscribedMachineIds;
        currentClaimedMachines = currentState.claimedMachineMetadata;
        currentMachines = currentState.machines ?? [];
      }

      // Check if not subscribed
      if (!currentMachineIds.contains(machineId)) {
        appLog.w('Not subscribed to machine: $machineId');
        return;
      }

      emit(
        MyMachinesSubscribing(
          subscribedMachineIds: currentMachineIds,
          machines: currentState is MyMachinesLoaded
              ? currentState.machines
              : null,
          claimedMachineMetadata: currentClaimedMachines,
        ),
      );

      // Unsubscribe from notification topic
      await _notificationService.unsubscribeFromMachine(machineId);

      // Reload from shared preferences to get updated list
      final updatedMachines = _sharedPreferencesService.getSubscribedMachines();

      // unclaim the machine
      _sharedPreferencesService.unclaimMachine(machineId);

      appLog.i('Successfully unsubscribed from machine: $machineId');
      emit(
        MyMachinesSubscribed(
          subscribedMachineIds: updatedMachines,
          machines: currentMachines,
          claimedMachineMetadata: currentClaimedMachines,
          operatingMachine: machine,
        ),
      );

      // wait for 1s, then emit
      Future.delayed(const Duration(seconds: 1), () {
        emit(
          MyMachinesLoaded(
            subscribedMachineIds: updatedMachines,
            machines: currentState is MyMachinesLoaded
                ? currentState.machines
                      ?.where((m) => m.machineId != machineId)
                      .toList()
                : null,
            claimedMachineMetadata: currentClaimedMachines,
          ),
        );
      });
    } catch (e) {
      appLog.e('Error unsubscribing from machine $machineId: $e');
      emit(MyMachinesError(message: 'Failed to unsubscribe from machine'));

      // Reload current state after error
      loadNotifyableMachines();
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
    }
    return 0;
  }

  /// Claim a machine (mark as "in use by you")
  Future<void> claimMachine(String machineId, {int? cycleTime}) async {
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
  /// // TODO: add FCM registration
  Future<void> unclaimMachine(String machineId) async {
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
