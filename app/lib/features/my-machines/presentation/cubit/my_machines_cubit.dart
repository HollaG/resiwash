import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/firebase_notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/services/local_notification_service.dart';
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
  final FirebaseNotificationService _notificationService;
  final ListMachinesUseCase _listMachinesUseCase;
  final MyMachinesUseCase _myMachinesUseCase;

  MyMachinesCubit({
    required SharedPreferencesService sharedPreferencesService,
    required FirebaseNotificationService notificationService,
    required ListMachinesUseCase listMachinesUseCase,
    required MyMachinesUseCase myMachinesUseCase,
  }) : _sharedPreferencesService = sharedPreferencesService,
       _notificationService = notificationService,
       _listMachinesUseCase = listMachinesUseCase,
       _myMachinesUseCase = myMachinesUseCase,
       super(MyMachinesInitial());

  Future<(List<MachineEntity>, List<MachineEntity>)> _getMyMachines() async {
    final subscribedMachineIds = _sharedPreferencesService
        .getSubscribedMachines();

    final claimedMachineMetadata = _sharedPreferencesService
        .getClaimedMachinesMetadata();

    final machineIdsToLoad = <String>{
      ...subscribedMachineIds,
      ...claimedMachineMetadata.map((e) => e.machineId),
    }.toList();

    if (machineIdsToLoad.isEmpty) {
      return (<MachineEntity>[], <MachineEntity>[]);
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

        // split the machines into subscribed and claimed
        final subscribedMachines = machines
            .where(
              (machine) => subscribedMachineIds.contains(machine.machineId),
            )
            .toList();

        final claimedMachines = machines
            .where(
              (machine) => claimedMachineMetadata.any(
                (claimed) => claimed.machineId == machine.machineId,
              ),
            )
            .toList();

        return (subscribedMachines, claimedMachines);
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
        var (subscribedMachines, claimedMachines) = await _getMyMachines();

        final subscribedMachineIds = _sharedPreferencesService
            .getSubscribedMachines();

        final claimedMachineMetadata = _sharedPreferencesService
            .getClaimedMachinesMetadata();

        emit(
          MyMachinesLoaded(
            subscribedMachineIds: subscribedMachineIds,
            subscribedMachines: subscribedMachines,
            claimedMachineMetadata: claimedMachineMetadata,
            claimedMachines: claimedMachines,
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

  Future<void> refreshMyMachines() async {
    final currentState = state;
    if (currentState is MyMachinesLoaded) {
      try {
        List<String> currentMachineIds = [];
        List<ClaimedMachineMetadata> currentClaimedMachineMetadata = [];
        List<MachineEntity> currentSubscribedMachines = [];
        List<MachineEntity> currentClaimedMachinesEntities = [];

        if (currentState is MyMachinesLoaded) {
          currentMachineIds = currentState.subscribedMachineIds;
          currentClaimedMachineMetadata = currentState.claimedMachineMetadata;
          currentSubscribedMachines = currentState.subscribedMachines ?? [];
          currentClaimedMachinesEntities = currentState.claimedMachines ?? [];
        }

        emit(
          MyMachinesRefreshing(
            subscribedMachineIds: currentMachineIds,
            subscribedMachines: currentSubscribedMachines,
            claimedMachineMetadata: currentClaimedMachineMetadata,
            claimedMachines: currentClaimedMachinesEntities,
          ),
        );

        var (subscribedMachines, claimedMachines) = await _getMyMachines();

        final subscribedMachineIds = _sharedPreferencesService
            .getSubscribedMachines();

        final claimedMachineMetadata = _sharedPreferencesService
            .getClaimedMachinesMetadata();

        emit(
          MyMachinesLoaded(
            subscribedMachineIds: subscribedMachineIds,
            subscribedMachines: subscribedMachines,
            claimedMachineMetadata: claimedMachineMetadata,
            claimedMachines: claimedMachines,
          ),
        );
      } catch (e) {
        appLog.e('Error refreshing claimed machines: $e');
        // Optionally, you can emit an error state or keep the current state
      }
    }
  }

  /// REFRESHES
  /// Refresh claimed machines only
  Future<void> refreshClaimedMachines() async {
    // TODO: emit loading state
    final currentState = state;
    if (currentState is MyMachinesLoaded) {
      try {
        var (subscribedMachines, claimedMachines) = await _getMyMachines();

        emit(
          MyMachinesLoaded(
            subscribedMachineIds: currentState.subscribedMachineIds,
            subscribedMachines: subscribedMachines,
            claimedMachineMetadata: currentState.claimedMachineMetadata,
            claimedMachines: claimedMachines,
          ),
        );
      } catch (e) {
        appLog.e('Error refreshing claimed machines: $e');
        // Optionally, you can emit an error state or keep the current state
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
    List<ClaimedMachineMetadata> currentClaimedMachineMetadata = [];
    List<MachineEntity> currentSubscribedMachines = [];
    List<MachineEntity> currentClaimedMachinesEntities = [];

    if (currentState is MyMachinesLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentClaimedMachineMetadata = currentState.claimedMachineMetadata;
      currentSubscribedMachines = currentState.subscribedMachines ?? [];
      currentClaimedMachinesEntities = currentState.claimedMachines ?? [];
    }

    try {
      emit(
        MyMachinesSubscribing(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentSubscribedMachines,
          claimedMachineMetadata: currentClaimedMachineMetadata,
          claimedMachines: currentClaimedMachinesEntities,
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
          subscribedMachines: currentSubscribedMachines,
          claimedMachineMetadata: currentClaimedMachineMetadata,
          claimedMachines: currentClaimedMachinesEntities,
          operatingMachine: machine,
        ),
      );

      // wait for 1s, then emit
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          final (subscribedMachines, claimedMachines) = await _getMyMachines();
          emit(
            MyMachinesLoaded(
              subscribedMachineIds: updatedMachines,
              subscribedMachines: subscribedMachines,
              claimedMachineMetadata: currentState is MyMachinesLoaded
                  ? currentState.claimedMachineMetadata
                  : [],
              claimedMachines: claimedMachines,
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
          claimedMachineMetadata: currentClaimedMachineMetadata,
          subscribedMachines: currentSubscribedMachines,
          subscribedMachineIds: currentMachineIds,
          operatingMachine: machine,
          claimedMachines: currentClaimedMachinesEntities,
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
    List<ClaimedMachineMetadata> currentClaimedMachinesMetadata = [];
    List<MachineEntity> currentMachines = [];
    List<MachineEntity> currentClaimedMachinesEntities = [];

    if (currentState is MyMachinesLoaded) {
      currentMachineIds = currentState.subscribedMachineIds;
      currentClaimedMachinesMetadata = currentState.claimedMachineMetadata;
      currentMachines = currentState.subscribedMachines ?? [];
      currentClaimedMachinesEntities = currentState.claimedMachines ?? [];
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
          subscribedMachines: currentMachines,
          claimedMachineMetadata: currentClaimedMachinesMetadata,
          operatingMachine: machine,
          claimedMachines: currentClaimedMachinesEntities,
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
          subscribedMachines: currentMachines,
          claimedMachineMetadata: currentClaimedMachinesMetadata,
          operatingMachine: machine,
          claimedMachines: currentClaimedMachinesEntities,
        ),
      );

      // wait for 1s, then emit
      Future.delayed(const Duration(seconds: 1), () async {
        emit(
          MyMachinesLoaded(
            subscribedMachineIds: updatedMachines,
            subscribedMachines: currentMachines
                .filter((machine) => machine.machineId != machineId)
                .toList(), // note: we don't need to reload machines here, just remove the unsubscribed one
            claimedMachineMetadata: currentClaimedMachinesMetadata,
            claimedMachines: currentClaimedMachinesEntities,
          ),
        );
      });
    } catch (e) {
      appLog.e('Error unsubscribing from machine $machineId: $e');
      emit(
        MyMachinesSubscribeError(
          message: 'Failed to unsubscribe from machine',
          claimedMachineMetadata: currentClaimedMachinesMetadata,
          subscribedMachines: currentMachines,
          subscribedMachineIds: currentMachineIds,
          operatingMachine: machine,
          claimedMachines: currentClaimedMachinesEntities,
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
  /// NOTE: the storage supports claiming multiple machines. However, we restrict it to one-to-one logically.
  ///       If we ever expand in the future, we can.
  ///       As such, when we claim a machine, we do not append to existing claimed machines, but replace the whole List.
  Future<void> claimMachine(MachineEntity machine, {int cycleTime = 30}) async {
    final machineId = machine.machineId;
    try {
      final currentState = state;
      List<String> currentMachineIds = [];
      List<ClaimedMachineMetadata> currentClaimedMachineMetadata = [];
      List<MachineEntity> currentMachines = [];
      List<MachineEntity> currentClaimedMachinesEntities = [];

      if (currentState is MyMachinesLoaded) {
        currentMachineIds = currentState.subscribedMachineIds;
        currentClaimedMachineMetadata = currentState.claimedMachineMetadata;
        currentMachines = currentState.subscribedMachines ?? [];
        currentClaimedMachinesEntities = currentState.claimedMachines ?? [];
      }

      final oldClaimedMachineId = currentClaimedMachineMetadata.isNotEmpty
          ? currentClaimedMachineMetadata.first.machineId
          : null;

      emit(
        MyMachinesClaiming(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          claimedMachineMetadata: currentClaimedMachineMetadata,
          operatingMachine: machine,
          claimedMachines: currentClaimedMachinesEntities,
        ),
      );

      // get fcm token
      final fcmToken = await _notificationService.getFcmToken();

      // Call use case to claim machine

      final myMachinesEither = await _myMachinesUseCase.claim(
        machineId,
        cycleTime: cycleTime, // for now
        fcmToken: fcmToken,
      );

      myMachinesEither.fold(
        (failure) {
          appLog.e('Error claiming machine $machineId: ${failure.message}');

          // // Emit error state with the actual error message
          emit(
            MyMachinesErrorClaiming(
              subscribedMachineIds: currentMachineIds,
              subscribedMachines: currentMachines,
              claimedMachineMetadata: currentClaimedMachineMetadata,
              claimedMachines: currentClaimedMachinesEntities,
              operatingMachine: machine,
              message: failure.message,
            ),
          );
        },
        (_) async {
          // Add to SharedPreferences with optional cycle time
          final updatedClaimedMetadataForThisMachine = _sharedPreferencesService
              .claimMachine(machineId, cycleTime: cycleTime);

          // Reload state to reflect changes
          final updatedClaimedMetadata = _sharedPreferencesService
              .getClaimedMachinesMetadata();

          final (subscribedMachines, claimedMachines) = await _getMyMachines();
          emit(
            MyMachinesClaimed(
              subscribedMachineIds: currentMachineIds,
              subscribedMachines: subscribedMachines,
              claimedMachineMetadata: updatedClaimedMetadata,
              operatingMachine: machine,
              claimedMachines: claimedMachines,
            ),
          );

          sl<LocalNotificationService>().showClaimedNotification(
            machine,
            updatedClaimedMetadataForThisMachine,
          );

          // unclaim the old
          if (oldClaimedMachineId != null) {
            final oldClaimedMachine = currentClaimedMachinesEntities.firstWhere(
              (m) => m.machineId == oldClaimedMachineId,
            );
            emit(
              MyMachinesUnclaimed(
                subscribedMachineIds: currentMachineIds,
                subscribedMachines: subscribedMachines,
                claimedMachineMetadata: updatedClaimedMetadata,
                operatingMachine: oldClaimedMachine,
                claimedMachines: claimedMachines,
              ),
            );
          }

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
      List<ClaimedMachineMetadata> currentClaimedMachinesMetadata = [];
      List<MachineEntity> currentMachines = [];
      List<MachineEntity> currentClaimedMachinesEntities = [];

      if (currentState is MyMachinesLoaded) {
        currentMachineIds = currentState.subscribedMachineIds;
        currentClaimedMachinesMetadata = currentState.claimedMachineMetadata;
        currentMachines = currentState.subscribedMachines ?? [];
        currentClaimedMachinesEntities = currentState.claimedMachines ?? [];
      }

      emit(
        MyMachinesClaiming(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          claimedMachines: currentClaimedMachinesEntities,
          claimedMachineMetadata: currentClaimedMachinesMetadata,
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
              subscribedMachines: currentMachines,
              claimedMachineMetadata: currentClaimedMachinesMetadata,
              operatingMachine: machine,
              message: failure.message,
              claimedMachines: currentClaimedMachinesEntities,
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
              .getClaimedMachinesMetadata();

          emit(
            MyMachinesUnclaimed(
              subscribedMachineIds: currentMachineIds,
              subscribedMachines: currentMachines,
              claimedMachines: currentClaimedMachinesEntities
                  .filter((m) => m.machineId != machineId)
                  .toList(),
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

  Future<void> unclaimMachineId(String machineId) async {
    try {
      final currentState = state;
      List<String> currentMachineIds = [];
      List<ClaimedMachineMetadata> currentClaimedMachinesMetadata = [];
      List<MachineEntity> currentMachines = [];
      List<MachineEntity> currentClaimedMachinesEntities = [];

      // current state
      appLog.i("current state: $currentState");

      if (currentState is MyMachinesLoaded) {
        currentMachineIds = currentState.subscribedMachineIds;
        currentClaimedMachinesMetadata = currentState.claimedMachineMetadata;
        currentMachines = currentState.subscribedMachines ?? [];
        currentClaimedMachinesEntities = currentState.claimedMachines ?? [];
      }

      // debug print all lists
      appLog.i('Current Machine IDs: $currentMachineIds');
      appLog.i(
        'Current Claimed Machines Metadata: $currentClaimedMachinesMetadata',
      );
      appLog.i('Current Machines: $currentMachines');
      appLog.i(
        'Current Claimed Machines Entities: $currentClaimedMachinesEntities',
      );

      final machine = currentClaimedMachinesEntities.firstWhere(
        (m) => m.machineId == machineId,
      );

      emit(
        MyMachinesClaiming(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          claimedMachines: currentClaimedMachinesEntities,
          claimedMachineMetadata: currentClaimedMachinesMetadata,
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
              subscribedMachines: currentMachines,
              claimedMachineMetadata: currentClaimedMachinesMetadata,
              operatingMachine: machine,
              message: failure.message,
              claimedMachines: currentClaimedMachinesEntities,
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
              .getClaimedMachinesMetadata();

          emit(
            MyMachinesUnclaimed(
              subscribedMachineIds: currentMachineIds,
              subscribedMachines: currentMachines,
              claimedMachines: currentClaimedMachinesEntities
                  .filter((m) => m.machineId != machineId)
                  .toList(),
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

  Future<void> updateCycleTime(MachineEntity machine, int cycleTime) async {
    final machineId = machine.machineId;
    try {
      final currentState = state;
      List<String> currentMachineIds = [];
      List<ClaimedMachineMetadata> currentClaimedMachineMetadata = [];
      List<MachineEntity> currentMachines = [];
      List<MachineEntity> currentClaimedMachinesEntities = [];

      if (currentState is MyMachinesLoaded) {
        currentMachineIds = currentState.subscribedMachineIds;
        currentClaimedMachineMetadata = currentState.claimedMachineMetadata;
        currentMachines = currentState.subscribedMachines ?? [];
        currentClaimedMachinesEntities = currentState.claimedMachines ?? [];
      }

      final oldClaimedMachineId = currentClaimedMachineMetadata.isNotEmpty
          ? currentClaimedMachineMetadata.first.machineId
          : null;

      emit(
        MyMachinesClaiming(
          subscribedMachineIds: currentMachineIds,
          subscribedMachines: currentMachines,
          claimedMachineMetadata: currentClaimedMachineMetadata,
          operatingMachine: machine,
          claimedMachines: currentClaimedMachinesEntities,
        ),
      );

      // get fcm token
      final fcmToken = await _notificationService.getFcmToken();

      // Call use case to claim machine

      final myMachinesEither = await _myMachinesUseCase.updateClaim(
        machineId,
        cycleTime: cycleTime,
        fcmToken: fcmToken,
      );

      myMachinesEither.fold(
        (failure) {
          appLog.e('Error claiming machine $machineId: ${failure.message}');

          // // Emit error state with the actual error message
          emit(
            MyMachinesErrorClaiming(
              subscribedMachineIds: currentMachineIds,
              subscribedMachines: currentMachines,
              claimedMachineMetadata: currentClaimedMachineMetadata,
              claimedMachines: currentClaimedMachinesEntities,
              operatingMachine: machine,
              message: failure.message,
            ),
          );
        },
        (_) async {
          // Add to SharedPreferences with optional cycle time
          _sharedPreferencesService.updateClaimedMachineCycleTime(
            machineId,
            cycleTime,
          );

          // // Reload state to reflect changes
          final updatedClaimedMetadata = _sharedPreferencesService
              .getClaimedMachinesMetadata();

          // final (subscribedMachines, claimedMachines) = await _getMyMachines();
          emit(
            MyMachinesClaimed(
              subscribedMachineIds: currentMachineIds,
              subscribedMachines: currentMachines,
              claimedMachineMetadata: updatedClaimedMetadata,
              operatingMachine: machine,
              claimedMachines: currentClaimedMachinesEntities,
            ),
          );
          // // unclaim the old
          // if (oldClaimedMachineId != null) {
          //   final oldClaimedMachine = currentClaimedMachinesEntities.firstWhere(
          //     (m) => m.machineId == oldClaimedMachineId,
          //   );
          //   emit(
          //     MyMachinesClaimed(
          //       subscribedMachineIds: currentMachineIds,
          //       subscribedMachines: subscribedMachines,
          //       claimedMachineMetadata: updatedClaimedMetadata,
          //       operatingMachine: oldClaimedMachine,
          //       claimedMachines: claimedMachines,
          //     ),
          //   );
          // }

          appLog.i(
            'Updated claim for machine: $machineId with cycleTime: $cycleTime',
          );
        },
      );
    } catch (e) {
      appLog.e('Error claiming machine $machineId: $e');
    }
  }

  /// Update the cycle time for a claimed machine
  void updateClaimedMachineCycleTime(
    MachineEntity machine,
    int? cycleTime,
  ) async {
    try {
      // _sharedPreferencesService.updateClaimedMachineCycleTime(
      //   machineId,
      //   cycleTime,
      // );

      // get fcm token
      final fcmToken = await _notificationService.getFcmToken();

      await unclaimMachine(machine);
      print("-------------- unclaimed");
      await claimMachine(machine, cycleTime: cycleTime ?? 30);

      // send to backend

      // State doesn't change for this operation (IDs remain the same)
      appLog.i(
        'Updated cycle time for machine: ${machine.machineId} to $cycleTime',
      );
    } catch (e) {
      appLog.e(
        'Error updating cycle time for machine ${machine.machineId}: $e',
      );
    }
  }
}
