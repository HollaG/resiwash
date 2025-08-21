import 'package:resiwash/core/shared/machine/data/models/machine_model.dart';
import 'package:resiwash/core/shared/machine/domain/entities/machine_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:resiwash/core/shared/room/domain/entities/room_entity.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';

enum CountKey { total, available }

sealed class OverviewState extends Equatable {
  const OverviewState();

  @override
  List<Object?> get props => [];
}

class OverviewInitial extends OverviewState {}

class OverviewLoading extends OverviewState {}

class OverviewLoaded extends OverviewState {
  final List<MachineEntity> machines;
  final Map<String, List<MachineEntity>> machinesByRoom; // UI-specific grouping
  final List<AreaEntity> locations;

  // calculated
  // int get totalWasherCount => machines.where((m) => m.type == MachineType.washer).length;
  // int get freeWasherCount => machines.where((m) => m.type == MachineType.washer && m.currentStatus == MachineStatus.available).length;

  Map<CountKey, int> getTypeCount(MachineType type) {
    return ({
      CountKey.total: machines.where((m) => m.type == type).length,
      CountKey.available: machines
          .where(
            (m) => m.type == type && m.currentStatus == MachineStatus.available,
          )
          .length,
    });
  }

  List<MachineEntity> getMachinesInRoom(String roomId) {
    return machinesByRoom[roomId] ?? [];
  }

  List<AreaEntity> getAreasWithRooms() {
    // return
    return locations;
  }

  AreaEntity getAreaOfRoom(String roomId) {
    return locations.firstWhere(
      (area) => area.rooms!.any((room) => room.roomId == roomId),
      orElse: () =>
          throw StateError('No AreaEntity found for the given roomId'),
    );
  }

  RoomEntity getRoomById(String roomId) {
    return getAreaOfRoom(roomId).rooms!.firstWhere(
      (room) => room.roomId == roomId,
      orElse: () =>
          throw StateError('No RoomEntity found for the given roomId'),
    );
  }

  const OverviewLoaded({
    required this.machines,
    required this.machinesByRoom,
    required this.locations,
  });
}

class OverviewError extends OverviewState {
  final String message;

  const OverviewError(this.message);
}
