import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/firebase_notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/services/local_notification_service.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/core/utils/snackbar_helper.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/params/get_machine_params.dart';
import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/my-machines/domain/usecases/my_machines_usecase.dart';
import 'claim_state.dart';

/// Cubit for managing claimed machines
///
/// This cubit handles:
/// - Loading claimed machine data from repository
/// - Claiming machines (hits backend)
/// - Unclaiming machines (hits backend)
/// - Updating cycle time for claimed machines
class ClaimCubit extends Cubit<ClaimState> {
  final SharedPreferencesService _sharedPreferencesService;
  final FirebaseNotificationService _notificationService;
  final ListMachinesUseCase _listMachinesUseCase;
  final MyMachinesUseCase _myMachinesUseCase;
  final GetMachineUseCase _getMachineUseCase;

  ClaimCubit({
    required SharedPreferencesService sharedPreferencesService,
    required FirebaseNotificationService notificationService,
    required ListMachinesUseCase listMachinesUseCase,
    required MyMachinesUseCase myMachinesUseCase,
    required GetMachineUseCase getMachineUseCase,
  }) : _sharedPreferencesService = sharedPreferencesService,
       _notificationService = notificationService,
       _listMachinesUseCase = listMachinesUseCase,
       _myMachinesUseCase = myMachinesUseCase,
       _getMachineUseCase = getMachineUseCase,
       super(const ClaimInitial());

  /// Load claimed machines from local storage and fetch their data
  Future<List<MachineEntity>> _getClaimedMachines() async {
    final claimedMachineMetadata = _sharedPreferencesService
        .getClaimedMachinesMetadata();

    if (claimedMachineMetadata.isEmpty) {
      return <MachineEntity>[];
    }

    final machineIds = claimedMachineMetadata.map((e) => e.machineId).toList();

    appLog.d('Loading ${machineIds.length} claimed machines from repository');

    // Fetch machines from repository
    final result = await _listMachinesUseCase(
      ListMachinesParams(machineIds: machineIds, extra: true),
    );

    return result.fold(
      (failure) {
        appLog.e('Error loading claimed machines: ${failure.message}');
        throw Failure(message: failure.message);
      },
      (machines) {
        appLog.i('Successfully loaded ${machines.length} claimed machines');
        return machines;
      },
    );
  }

  /// Load all claimed machines
  Future<void> loadClaimedMachines() async {
    try {
      if (isClosed) return;
      emit(
        ClaimLoading(
          claimedMachineMetadata: _sharedPreferencesService
              .getClaimedMachinesMetadata(),
        ),
      );

      try {
        final claimedMachines = await _getClaimedMachines();
        if (isClosed) return;
        final claimedMachineMetadata = _sharedPreferencesService
            .getClaimedMachinesMetadata();

        if (isClosed) return;
        emit(
          ClaimLoaded(
            claimedMachineMetadata: claimedMachineMetadata,
            claimedMachines: claimedMachines,
          ),
        );
      } catch (e) {
        appLog.e('Error loading claimed machines: $e');
        if (isClosed) return;
        emit(const ClaimError(message: 'Failed to load claimed machines'));
      }
    } catch (e) {
      appLog.e('Error loading claimed machines: $e');
      if (isClosed) return;
      emit(const ClaimError(message: 'Failed to load claimed machines'));
    }
  }

  /// Refresh claimed machines list
  Future<void> refreshClaimedMachines() async {
    final currentState = state;
    if (currentState is ClaimLoaded) {
      try {
        if (isClosed) return;
        emit(
          ClaimRefreshing(
            claimedMachineMetadata: currentState.claimedMachineMetadata,
            claimedMachines: currentState.claimedMachines,
          ),
        );

        final claimedMachines = await _getClaimedMachines();
        if (isClosed) return;
        final claimedMachineMetadata = _sharedPreferencesService
            .getClaimedMachinesMetadata();

        if (isClosed) return;
        emit(
          ClaimLoaded(
            claimedMachineMetadata: claimedMachineMetadata,
            claimedMachines: claimedMachines,
          ),
        );
      } catch (e) {
        appLog.e('Error refreshing claimed machines: $e');
        // Keep current state on error
      }
    }
  }

  /// Claim a machine (mark as "in use by you")
  /// NOTE: hits the backend
  /// NOTE: the storage supports claiming multiple machines. However, we restrict it to one-to-one logically.
  ///       If we ever expand in the future, we can.
  ///       As such, when we claim a machine, we do not append to existing claimed machines, but replace the whole List.
  /// [UPDATE 9 FEB 2026]: Now supports multiple claimed machines.
  Future<bool> claimMachine(MachineEntity machine, {int cycleTime = 30}) async {
    final machineId = machine.machineId;
    final currentState = state;
    List<ClaimedMachineMetadata> currentClaimedMachineMetadata = [];
    List<MachineEntity>? currentClaimedMachines;

    if (currentState is ClaimLoaded) {
      currentClaimedMachineMetadata = currentState.claimedMachineMetadata;
      currentClaimedMachines = currentState.claimedMachines;

      print(
        "debug currentClaimedMachines.length: ${currentClaimedMachines?.length}",
      );

      // if (currentClaimedMachines != null && currentClaimedMachines.length > 4) {
      //   SnackbarHelper.showInfo(
      //     message:
      //         "You can only claim up to 5 machines at a time. Please unclaim a machine before claiming another one.",
      //   );
      //   return false;
      // }
    }

    if (isClosed) return false;
    emit(
      Claiming(
        claimedMachineMetadata: currentClaimedMachineMetadata,
        claimedMachines: currentClaimedMachines,
        operatingMachine: machine,
      ),
    );
    try {
      // Get FCM token
      final fcmToken = await _notificationService.getFcmToken();

      // Call use case to claim machine
      final myMachinesEither = await _myMachinesUseCase.claim(
        machineId,
        cycleTime: cycleTime,
        fcmToken: fcmToken,
      );

      final didClaim = await myMachinesEither.fold(
        (failure) async {
          appLog.e('Error claiming machine $machineId: ${failure.message}');

          if (isClosed) return false;
          emit(
            ClaimOperationError(
              claimedMachineMetadata: currentClaimedMachineMetadata,
              claimedMachines: currentClaimedMachines,
              operatingMachine: machine,
              message: failure.message,
            ),
          );
          return false;
        },
        (_) async {
          // Add to SharedPreferences with cycle time
          final updatedClaimedMetadataForThisMachine = _sharedPreferencesService
              .claimMachine(machineId, cycleTime: cycleTime);

          // Reload state to reflect changes
          final updatedClaimedMetadata = _sharedPreferencesService
              .getClaimedMachinesMetadata();

          final claimedMachines = await _getClaimedMachines();

          if (isClosed) return false;
          emit(
            Claimed(
              claimedMachineMetadata: updatedClaimedMetadata,
              claimedMachines: claimedMachines,
              operatingMachine: machine,
            ),
          );

          // refresh the machine, then show the claim status
          // Show notification

          final params = GetMachineParams(extra: false);
          final updatedMachineEither = await _getMachineUseCase.call(
            machineId: machineId,
            params: params,
          );

          return updatedMachineEither.fold(
            (failure) {
              // If refresh fails, still show notification with old machine data
              appLog.w('Failed to refresh machine data: ${failure.message}');
              // TODO: show error notif
              emit(
                ClaimOperationError(
                  claimedMachineMetadata: currentClaimedMachineMetadata,
                  claimedMachines: currentClaimedMachines,
                  operatingMachine: machine,
                  message: "Claim succeeded. Please refresh the page manually.",
                ),
              );
              return true;
            },
            (updatedMachine) {
              // Show notification with refreshed machine data
              // sl<LocalNotificationService>().showClaimedNotification(
              //   updatedMachine,
              //   updatedClaimedMetadataForThisMachine,
              // );

              // TODO: update all machine data in state when claimed
              appLog.i(
                'Claimed machine: $machineId with cycleTime: $cycleTime',
              );

              return true;
            },
          );
        },
      );

      return didClaim;
    } catch (e) {
      appLog.e('Error claiming machine $machineId: $e');

      emit(
        ClaimOperationError(
          claimedMachineMetadata: currentClaimedMachineMetadata,
          claimedMachines: currentClaimedMachines,
          operatingMachine: machine,
          message: e.toString(),
        ),
      );

      return false;
    }
  }

  /// Unclaim a machine (remove from "in use by you")
  /// NOTE: hits the backend
  Future<void> unclaimMachine(MachineEntity machine) async {
    final machineId = machine.machineId;
    final currentState = state;
    List<ClaimedMachineMetadata> currentClaimedMachineMetadata = [];
    List<MachineEntity>? currentClaimedMachines;

    if (currentState is ClaimLoaded) {
      currentClaimedMachineMetadata = currentState.claimedMachineMetadata;
      currentClaimedMachines = currentState.claimedMachines;
    }

    if (isClosed) return;
    emit(
      Claiming(
        claimedMachineMetadata: currentClaimedMachineMetadata,
        claimedMachines: currentClaimedMachines,
        operatingMachine: machine,
      ),
    );
    try {
      // Get FCM token
      final fcmToken = await _notificationService.getFcmToken();

      // Call use case to unclaim machine
      final result = await _myMachinesUseCase.unclaim(
        machineId,
        fcmToken: fcmToken,
      );

      result.fold(
        (failure) {
          appLog.e('Error unclaiming machine $machineId: ${failure.message}');

          if (isClosed) return;
          emit(
            ClaimOperationError(
              claimedMachineMetadata: currentClaimedMachineMetadata,
              claimedMachines: currentClaimedMachines,
              operatingMachine: machine,
              message: failure.message,
            ),
          );
        },
        (_) {
          // Remove from SharedPreferences
          _sharedPreferencesService.unclaimMachine(machineId);

          // Cancel claimed notification
          sl<LocalNotificationService>().cancelClaimedNotification();

          if (Platform.isIOS) {
            sl<LocalNotificationService>().cancelLiveActivity(machineId);
          }

          // Reload state to reflect changes
          final updatedClaimedMetadata = _sharedPreferencesService
              .getClaimedMachinesMetadata();

          if (isClosed) return;
          emit(
            Unclaimed(
              claimedMachineMetadata: updatedClaimedMetadata,
              claimedMachines: currentClaimedMachines
                  ?.where((m) => m.machineId != machineId)
                  .toList(),
              operatingMachine: machine,
            ),
          );

          appLog.i('Unclaimed machine: $machineId');

          // TODO: this general info should be somewhere else, not in the cubit.
          SnackbarHelper.showSuccess(
            message: "Machine released. Thanks for using ResiWash!",
          );
        },
      );
    } catch (e) {
      appLog.e('Error unclaiming machine $machineId: $e');
      emit(
        ClaimOperationError(
          claimedMachineMetadata: currentClaimedMachineMetadata,
          claimedMachines: currentClaimedMachines,
          operatingMachine: machine,
          message: e.toString(),
        ),
      );
    }
  }

  /// Unclaim a machine by ID (when you only have the ID)
  Future<void> unclaimMachineById(String machineId) async {
    final currentState = state;
    List<MachineEntity>? currentClaimedMachines;

    List<ClaimedMachineMetadata> currentClaimedMachineMetadata = [];
    MachineEntity? machine;

    if (currentState is ClaimLoaded) {
      currentClaimedMachineMetadata = currentState.claimedMachineMetadata;
      currentClaimedMachines = currentState.claimedMachines;
    }

    if (currentClaimedMachines == null) {
      appLog.e('No claimed machines loaded');
      return;
    }
    try {
      machine = currentClaimedMachines.firstWhere(
        (m) => m.machineId == machineId,
      );
      await unclaimMachine(machine);
    } catch (e) {
      appLog.e('Error unclaiming machine $machineId: $e');
      if (machine == null) {
        emit(ClaimError(message: 'Machine not found'));
      } else {
        emit(
          ClaimOperationError(
            claimedMachineMetadata: currentClaimedMachineMetadata,
            claimedMachines: currentClaimedMachines,
            operatingMachine: machine,
            message: e.toString(),
          ),
        );
      }
    }
  }

  /// Check if a machine is claimed
  bool isMachineClaimed(String machineId) {
    return _sharedPreferencesService.isMachineClaimed(machineId);
  }

  /// Update the cycle time for a claimed machine
  /// NOTE: hits the backend
  Future<bool> updateCycleTime(MachineEntity machine, int cycleTime) async {
    final machineId = machine.machineId;
    try {
      final currentState = state;
      List<ClaimedMachineMetadata> currentClaimedMachineMetadata = [];
      List<MachineEntity>? currentClaimedMachines;

      if (currentState is ClaimLoaded) {
        currentClaimedMachineMetadata = currentState.claimedMachineMetadata;
        currentClaimedMachines = currentState.claimedMachines;
      }

      if (isClosed) return false;
      emit(
        Claiming(
          claimedMachineMetadata: currentClaimedMachineMetadata,
          claimedMachines: currentClaimedMachines,
          operatingMachine: machine,
        ),
      );

      // Get FCM token
      final fcmToken = await _notificationService.getFcmToken();

      // Call use case to update claim
      final myMachinesEither = await _myMachinesUseCase.updateClaim(
        machineId,
        cycleTime: cycleTime,
        fcmToken: fcmToken,
      );

      final didUpdate = await myMachinesEither.fold(
        (failure) async {
          appLog.e(
            'Error updating cycle time for machine $machineId: ${failure.message}',
          );

          if (isClosed) return false;
          emit(
            ClaimOperationError(
              claimedMachineMetadata: currentClaimedMachineMetadata,
              claimedMachines: currentClaimedMachines,
              operatingMachine: machine,
              message: failure.message,
            ),
          );
          return false;
        },
        (_) async {
          // Update in SharedPreferences
          _sharedPreferencesService.updateClaimedMachineCycleTime(
            machineId,
            cycleTime,
          );

          // Reload state to reflect changes
          final updatedClaimedMetadata = _sharedPreferencesService
              .getClaimedMachinesMetadata();

          if (isClosed) return false;
          emit(
            Claimed(
              claimedMachineMetadata: updatedClaimedMetadata,
              claimedMachines: currentClaimedMachines,
              operatingMachine: machine,
            ),
          );

          appLog.i('Updated cycle time for machine: $machineId to $cycleTime');
          return true;
        },
      );

      return didUpdate;
    } catch (e) {
      appLog.e('Error updating cycle time for machine $machineId: $e');

      return false;
    }
  }
}
