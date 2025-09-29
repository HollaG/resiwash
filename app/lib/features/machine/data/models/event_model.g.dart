// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map<String, dynamic> json) => EventModel(
  eventId: (json['eventId'] as num).toInt(),
  timestamp: json['timestamp'] as String,
  status: $enumDecode(_$MachineStatusEnumMap, json['status']),
  reading: (json['reading'] as num?)?.toDouble(),
);

Map<String, dynamic> _$EventModelToJson(EventModel instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'timestamp': instance.timestamp,
      'status': _$MachineStatusEnumMap[instance.status]!,
      'reading': instance.reading,
    };

const _$MachineStatusEnumMap = {
  MachineStatus.available: 'AVAILABLE',
  MachineStatus.inUse: 'IN_USE',
  MachineStatus.hasIssues: 'HAS_ISSUES',
  MachineStatus.unknown: 'UNKNOWN',
  MachineStatus.finishing: 'FINISHING',
};
