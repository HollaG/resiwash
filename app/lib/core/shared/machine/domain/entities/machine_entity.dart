import 'package:resiwash/core/shared/machine/data/models/machine_model.dart';
import 'package:resiwash/core/shared/room/domain/entities/room_entity.dart';

class MachineEntity {
  final int machineId;
  final String name;
  final String label;
  final MachineType type;

  final String imageUrl;

  final RoomEntity? room;
  final List<Map<String, dynamic>>? events;
  final List<Map<String, dynamic>>? rawEvents;
  final Map<String, dynamic>? sensorToMachine;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastUpdated;
  final DateTime lastChangeTime;

  final MachineStatus currentStatus; // "AVAILABLE" | "IN_USE" | "HAS_ISSUES"
  final MachineStatus previousStatus;

  MachineEntity({
    required this.machineId,
    required this.name,
    required this.label,
    required this.type,
    required this.imageUrl,
    this.room,
    this.events,
    this.rawEvents,
    this.sensorToMachine,
    required this.createdAt,
    required this.updatedAt,
    required this.lastUpdated,
    required this.lastChangeTime,
    required this.currentStatus,
    required this.previousStatus,
  });
}
