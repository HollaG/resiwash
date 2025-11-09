import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/my-machines/domain/usecases/my_machines_usecase.dart';
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
  final MyMachinesUseCase _myMachinesUseCase;

  MyMachinesCubit({
    required SharedPreferencesService sharedPreferencesService,
    required NotificationService notificationService,
    required ListMachinesUseCase listMachinesUseCase,
    required MyMachinesUseCase myMachinesUseCase,
  }) : _sharedPreferencesService = sharedPreferencesService,
       _notificationService = notificationService,
       _listMachinesUseCase = listMachinesUseCase,
       _myMachinesUseCase = myMachinesUseCase,
       super(MyMachinesInitial());

  Future<List<MachineEntity>> _getMyMachines() async {
    final subscribedMachineIds = _sharedPreferencesService
        .getSubscribedMachines();

    final claimedMachineMetadata = _sharedPreferencesService
        .getClaimedMachines();

    final machineIdsToLoad = [
      ...subscribedMachineIds,
      ...claimedMachineMetadata.map((e) => e.machineId),
    ].toSet().toList();

    if (machineIdsToLoad.isEmpty) {
      return [];
    }

    appLog.d(
      'Loading ${subscribedMachineIds.length} subscribed machines from repository',
    );

    // Fetch machines from repository
    final result = await _listMachinesUseCase(
      ListMachinesParams(machineIds: machineIdsToLoad, extra: true),
    );

    return result.fold(
      (failure) {
        appLog.e('Error loading machines: ${failure.message}');
        // emit(MyMachinesError(message: 'Failed to load machines'));
        // throw some error
        throw Failure(message: failure.message);
      },
      (machines) {
        appLog.i('Successfully loaded ${machines.length} machines');
        // emit(
        //   MyMachinesLoaded(
        //     subscribedMachineIds: subscribedMachineIds,
        //     machines: machines,
        //     claimedMachineMetadata: claimedMachineMetadata,
        //   ),
        // );
        return machines;
      },
    );
  }

  /// INIT METHOD
  /// Load full machine data from repository for subscribed machines
  /// This fetches the complete machine entities from the API
  Future<void> loadNotifyableMachines() async {
    try {
      emit(MyMachinesLoading());

      try {
        List<MachineEntity> machines = await _getMyMachines();

        final subscribedMachineIds = _sharedPreferencesService
            .getSubscribedMachines();

        final claimedMachineMetadata = _sharedPreferencesService
            .getClaimedMachines();

        emit(
          MyMachinesLoaded(
            subscribedMachineIds: subscribedMachineIds,
            machines: machines,
            claimedMachineMetadata: claimedMachineMetadata,
          ),
        );
      } catch (e) {
        appLog.e('Error loading machines: $e');
        emit(MyMachinesError(message: 'Failed to load machines'));
      }
    } catch (e) {
      appLog.e('Error loading subscribed machines: $e');
      emit(MyMachinesError(message: 'Failed to load subscribed machines'));
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
    List<ClaimedMachineMetadata> currentClaimedMachines = [];
    List<MachineEntity> currentMachines = [];

    if (currentState is MyMachinesLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentClaimedMachines = currentState.claimedMachineMetadata;
      currentMachines = currentState.machines ?? [];
    }

    try {
      emit(
        MyMachinesSubscribing(
          subscribedMachineIds: currentMachineIds,
          machines: currentMachines,
          claimedMachineMetadata: currentClaimedMachines,
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
      final updatedMachines = _sharedPreferencesService.getSubscribedMachines();

      // refresh the claimed machines list

      appLog.i('Successfully subscribed to machine: $machineId');

      emit(
        MyMachinesSubscribed(
          subscribedMachineIds: updatedMachines,
          machines: currentMachines,
          claimedMachineMetadata: currentClaimedMachines,
          operatingMachine: machine,
        ),
      );

      // wait for 1s, then emit
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          final machines = await _getMyMachines();
          emit(
            MyMachinesLoaded(
              subscribedMachineIds: updatedMachines,
              machines: machines,
              claimedMachineMetadata: currentState is MyMachinesLoaded
                  ? currentState.claimedMachineMetadata
                  : [],
            ),
          );
        } catch (e) {
          appLog.e('Error loading machines: $e');
          emit(MyMachinesError(message: 'Failed to load machines'));
          return;
        }
      });
    } catch (e) {
      appLog.e('Error subscribing to machine $machineId: $e');
      emit(
        MyMachinesSubscribeError(
          message: 'Failed to unsubscribe from machine',
          claimedMachineMetadata: currentClaimedMachines,
          machines: currentMachines,
          subscribedMachineIds: currentMachineIds,
          operatingMachine: machine,
        ),
      );
      // Reload current state after error
      loadNotifyableMachines();
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
    List<ClaimedMachineMetadata> currentClaimedMachines = [];
    List<MachineEntity> currentMachines = [];

    if (currentState is MyMachinesLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentClaimedMachines = currentState.claimedMachineMetadata;
      currentMachines = currentState.machines ?? [];
    }
    try {
      // Check if not subscribed
      if (!currentMachineIds.contains(machineId)) {
        appLog.w('Not subscribed to machine: $machineId');
        return;
      }

      emit(
        MyMachinesSubscribing(
          subscribedMachineIds: currentMachineIds,
          machines: currentMachines,
          claimedMachineMetadata: currentClaimedMachines,
          operatingMachine: machine,
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
        MyMachinesUnsubscribed(
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
            machines: currentMachines,
            claimedMachineMetadata: currentClaimedMachines,
          ),
        );
      });
    } catch (e) {
      appLog.e('Error unsubscribing from machine $machineId: $e');
      emit(
        MyMachinesSubscribeError(
          message: 'Failed to unsubscribe from machine',
          claimedMachineMetadata: currentClaimedMachines,
          machines: currentMachines,
          subscribedMachineIds: currentMachineIds,
          operatingMachine: machine,
        ),
      );

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
  /// NOTE: this function asserts that it is only called when you have NOT claimed the machine
  /// NOTE: hits the backend
  Future<void> claimMachine(MachineEntity machine, {int? cycleTime}) async {
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
        MyMachinesClaiming(
          subscribedMachineIds: currentMachineIds,
          machines: currentMachines,
          claimedMachineMetadata: currentClaimedMachines,
          operatingMachine: machine,
        ),
      );

      // get fcm token
      final fcmToken = await _notificationService.getFcmToken();

      // Call use case to claim machine

      final myMachinesEither = await _myMachinesUseCase.claim(
        machineId,
        cycleTime: 30, // for now
        fcmToken: fcmToken,
      );

      myMachinesEither.fold(
        (failure) {
          appLog.e('Error claiming machine $machineId: ${failure.message}');

          // // Emit error state with the actual error message
          emit(
            MyMachinesErrorClaiming(
              subscribedMachineIds: currentMachineIds,
              machines: currentMachines,
              claimedMachineMetadata: currentClaimedMachines,
              operatingMachine: machine,
              message: failure.message,
            ),
          );

          // // Restore previous state after a delay
          // Future.delayed(const Duration(seconds: 2), () {
          //   emit(
          //     MyMachinesLoaded(
          //       subscribedMachineIds: currentMachineIds,
          //       machines: currentMachines,
          //       claimedMachineMetadata: currentClaimedMachines,
          //     ),
          //   );
          // });
        },
        (_) {
          // Add to SharedPreferences with optional cycle time
          _sharedPreferencesService.claimMachine(
            machineId,
            cycleTime: cycleTime,
          );

          // Reload state to reflect changes
          final updatedClaimedMetadata = _sharedPreferencesService
              .getClaimedMachines();

          emit(
            MyMachinesClaimed(
              subscribedMachineIds: currentMachineIds,
              machines: currentMachines,
              claimedMachineMetadata: updatedClaimedMetadata,
              operatingMachine: machine,
            ),
          );

          // wait for 1s, then emit
          // Future.delayed(const Duration(seconds: 1), () {
          //   emit(
          //     MyMachinesLoaded(
          //       subscribedMachineIds: currentMachineIds,
          //       machines: currentMachines,
          //       claimedMachineMetadata: updatedClaimedMetadata,
          //     ),
          //   );
          // });

          appLog.i('Claimed machine: $machineId with cycleTime: $cycleTime');
        },
      );
    } catch (e) {
      appLog.e('Error claiming machine $machineId: $e');
    }
  }

  /// Unclaim a machine (remove from "in use by you")
  /// NOTE: hits the backend
  Future<void> unclaimMachine(MachineEntity machine) async {
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
        MyMachinesClaiming(
          subscribedMachineIds: currentMachineIds,
          machines: currentMachines,
          claimedMachineMetadata: currentClaimedMachines,
          operatingMachine: machine,
        ),
      );

      // get fcm token
      final fcmToken = await _notificationService.getFcmToken();

      // Call use case to claim machine
      final result = await _myMachinesUseCase.unclaim(
        machineId,
        fcmToken: fcmToken,
      );
      result.fold(
        (failure) {
          appLog.e('Error unclaiming machine $machineId: ${failure.message}');

          // // Emit error state with the actual error message
          emit(
            MyMachinesErrorClaiming(
              subscribedMachineIds: currentMachineIds,
              machines: currentMachines,
              claimedMachineMetadata: currentClaimedMachines,
              operatingMachine: machine,
              message: failure.message,
            ),
          );

          // // Restore previous state after a delay
          // Future.delayed(const Duration(seconds: 2), () {
          //   emit(
          //     MyMachinesLoaded(
          //       subscribedMachineIds: currentMachineIds,
          //       machines: currentMachines,
          //       claimedMachineMetadata: currentClaimedMachines,
          //     ),
          //   );
          // });
        },
        (_) {
          // Remove from SharedPreferences
          _sharedPreferencesService.unclaimMachine(machineId);

          // Reload state to reflect changes
          final updatedClaimedMetadata = _sharedPreferencesService
              .getClaimedMachines();

          emit(
            MyMachinesUnclaimed(
              subscribedMachineIds: currentMachineIds,
              machines: currentMachines,
              claimedMachineMetadata: updatedClaimedMetadata,
              operatingMachine: machine,
            ),
          );

          // wait for 1s, then emit
          // Future.delayed(const Duration(seconds: 1), () {
          //   emit(
          //     MyMachinesLoaded(
          //       subscribedMachineIds: currentMachineIds,
          //       machines: currentMachines,
          //       claimedMachineMetadata: updatedClaimedMetadata,
          //     ),
          //   );
          // });

          appLog.i('Unclaimed machine: $machineId');
        },
      );
    } catch (e) {
      appLog.e('Error unclaiming machine $machineId: $e');
    }
  }

  bool isMachineClaimed(String machineId) {
    return _sharedPreferencesService.isMachineClaimed(machineId);
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
