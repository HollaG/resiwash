// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MachineModel _$MachineModelFromJson(Map<String, dynamic> json) => MachineModel(
  machineId: (json['machineId'] as num).toInt(),
  name: json['name'] as String,
  label: json['label'] as String,
  type: $enumDecode(_$MachineTypeEnumMap, json['type']),
  imageUrl: json['imageUrl'] as String,
  room: json['room'] == null
      ? null
      : RoomModel.fromJson(json['room'] as Map<String, dynamic>),
  events: (json['events'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  rawEvents: (json['rawEvents'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  sensorToMachine: json['sensorToMachine'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  lastChangeTime: DateTime.parse(json['lastChangeTime'] as String),
  currentStatus: $enumDecode(_$MachineStatusEnumMap, json['currentStatus']),
  previousStatus: $enumDecode(_$MachineStatusEnumMap, json['previousStatus']),
);

Map<String, dynamic> _$MachineModelToJson(MachineModel instance) =>
    <String, dynamic>{
      'machineId': instance.machineId,
      'name': instance.name,
      'label': instance.label,
      'type': _$MachineTypeEnumMap[instance.type]!,
      'imageUrl': instance.imageUrl,
      'room': instance.room,
      'events': instance.events,
      'rawEvents': instance.rawEvents,
      'sensorToMachine': instance.sensorToMachine,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'lastChangeTime': instance.lastChangeTime.toIso8601String(),
      'currentStatus': _$MachineStatusEnumMap[instance.currentStatus]!,
      'previousStatus': _$MachineStatusEnumMap[instance.previousStatus]!,
    };

const _$MachineTypeEnumMap = {
  MachineType.unknown: 'unknown',
  MachineType.washer: 'washer',
  MachineType.dryer: 'dryer',
};

const _$MachineStatusEnumMap = {
  MachineStatus.available: 'available',
  MachineStatus.inUse: 'inUse',
  MachineStatus.hasIssues: 'hasIssues',
};
