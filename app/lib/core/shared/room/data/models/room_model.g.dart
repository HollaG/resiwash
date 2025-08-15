// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomModel _$RoomModelFromJson(Map<String, dynamic> json) => RoomModel(
  roomId: (json['roomId'] as num).toInt(),
  name: json['name'] as String,
  location: json['location'] as String,
  description: json['description'] as String,
  imageUrl: json['imageUrl'] as String,
  shortName: json['shortName'] as String,
  area: json['area'] == null
      ? null
      : AreaModel.fromJson(json['area'] as Map<String, dynamic>),
  machines: (json['machines'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  sensors: (json['sensors'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RoomModelToJson(RoomModel instance) => <String, dynamic>{
  'roomId': instance.roomId,
  'name': instance.name,
  'location': instance.location,
  'description': instance.description,
  'imageUrl': instance.imageUrl,
  'shortName': instance.shortName,
  'area': instance.area?.toJson(),
  'machines': instance.machines,
  'sensors': instance.sensors,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
