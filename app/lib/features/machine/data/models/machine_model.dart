// Enums ----------------------------------------------------------------------

import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:resiwash/features/room/data/models/room_model.dart';

part 'machine_model.g.dart';

enum MachineType { unknown, washer, dryer }

enum MachineStatus {
  @JsonValue('AVAILABLE')
  available('AVAILABLE'),
  @JsonValue('IN_USE')
  inUse('IN_USE'),
  @JsonValue('HAS_ISSUES')
  hasIssues('HAS_ISSUES');

  final String value;
  const MachineStatus(this.value);
}

// Model ----------------------------------------------------------------------
@JsonSerializable()
class MachineModel {
  final int machineId;
  final String name;
  final String label;
  final MachineType type;

  final String? imageUrl;

  final RoomModel? room;
  final int roomId;
  final List<Map<String, dynamic>>? events;
  final List<Map<String, dynamic>>? rawEvents;
  final Map<String, dynamic>? sensorToMachine;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUpdated;
  final DateTime? lastChangeTime;

  final MachineStatus? currentStatus; // "AVAILABLE" | "IN_USE" | "HAS_ISSUES"
  final MachineStatus? previousStatus;

  const MachineModel({
    required this.machineId,
    required this.name,
    required this.label,
    required this.type,
    this.imageUrl,
    required this.roomId,
    this.room,
    this.events,
    this.rawEvents,
    this.sensorToMachine,
    required this.createdAt,
    required this.updatedAt,
    this.lastUpdated,
    this.lastChangeTime,
    this.currentStatus,
    this.previousStatus,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) =>
      _$MachineModelFromJson(json);
  Map<String, dynamic> toJson() => _$MachineModelToJson(this);

  // domain mapping
  MachineEntity toEntity() => MachineEntity(
    machineId: machineId.toString(),
    name: name,
    label: label,
    type: type,
    imageUrl: imageUrl,
    roomId: roomId.toString(),
    room: room?.toEntity(),
    events: events,
    rawEvents: rawEvents,
    sensorToMachine: sensorToMachine,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastUpdated: lastUpdated,
    lastChangeTime: lastChangeTime,
    currentStatus: currentStatus,
    previousStatus: previousStatus,
  );
}
