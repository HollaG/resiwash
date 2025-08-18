// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  eventId: (json['eventId'] as num).toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  readings: (json['readings'] as List<dynamic>)
      .map((e) => Reading.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: $enumDecodeNullable(_$MachineStatusEnumMap, json['status']),
  statusCode: (json['statusCode'] as num?)?.toInt(),
  machine: json['machine'] == null
      ? null
      : MachineModel.fromJson(json['machine'] as Map<String, dynamic>),
  machineId: (json['machineId'] as num?)?.toInt(),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'eventId': instance.eventId,
  'timestamp': instance.timestamp.toIso8601String(),
  'status': _$MachineStatusEnumMap[instance.status],
  'statusCode': instance.statusCode,
  'readings': instance.readings,
  'machine': instance.machine,
  'machineId': instance.machineId,
};

const _$MachineStatusEnumMap = {
  MachineStatus.available: 'AVAILABLE',
  MachineStatus.inUse: 'IN_USE',
  MachineStatus.hasIssues: 'HAS_ISSUES',
};
