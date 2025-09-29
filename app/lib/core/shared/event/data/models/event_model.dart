// MachineStatus as per your TS:
// AVAILABLE | IN_USE | HAS_ISSUES
import 'package:resiwash/core/shared/event/domain/entities/event_entity.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

class Reading {
  Reading({required this.value, required this.threshold});

  num value;
  num threshold;

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
    value: (json['value'] as num),
    threshold: (json['threshold'] as num),
  );

  Map<String, dynamic> toJson() => {'value': value, 'threshold': threshold};
}

@JsonSerializable()
class Event {
  Event({
    required this.eventId,
    required this.timestamp,
    required this.readings,
    this.status,
    this.statusCode,
    this.machine,
    this.machineId,
  });

  int eventId;
  DateTime timestamp;
  MachineStatus? status; // 'AVAILABLE' | 'IN_USE' | 'HAS_ISSUES'
  int? statusCode; // deprecated in TS, kept for compatibility
  List<Reading> readings;

  // Relation (either one may be present depending on your API response)
  MachineModel? machine; // replace with Machine if you have a model
  int? machineId;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);

  EventEntity toEntity() => EventEntity(
    eventId: eventId,
    timestamp: timestamp,
    status: status,
    statusCode: statusCode,
    readings: readings,
    machine: machine?.toEntity(),
    machineId: machineId,
  );
}
