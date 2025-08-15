import 'package:resiwash/core/shared/event/data/models/event_model.dart';
import 'package:resiwash/core/shared/machine/data/models/machine_model.dart';
import 'package:resiwash/core/shared/machine/domain/entities/machine_entity.dart';

class EventEntity {
  int eventId;
  DateTime timestamp;
  MachineStatus? status; // 'AVAILABLE' | 'IN_USE' | 'HAS_ISSUES'
  int? statusCode; // deprecated in TS, kept for compatibility
  List<Reading> readings;

  // Relation (either one may be present depending on your API response)
  MachineEntity? machine; // replace with Machine if you have a model
  int? machineId;

  EventEntity({
    required this.eventId,
    required this.timestamp,
    this.status,
    this.statusCode,
    required this.readings,
    this.machine,
    this.machineId,
  });
}
