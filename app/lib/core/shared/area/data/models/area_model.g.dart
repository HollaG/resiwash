// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'area_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AreaModel _$AreaModelFromJson(Map<String, dynamic> json) => AreaModel(
  areaId: (json['areaId'] as num).toInt(),
  name: json['name'] as String,
  location: json['location'] as String,
  description: json['description'] as String,
  imageUrl: json['imageUrl'] as String,
  shortName: json['shortName'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  rooms: (json['rooms'] as List<dynamic>?)
      ?.map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AreaModelToJson(AreaModel instance) => <String, dynamic>{
  'areaId': instance.areaId,
  'name': instance.name,
  'location': instance.location,
  'description': instance.description,
  'imageUrl': instance.imageUrl,
  'shortName': instance.shortName,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'rooms': instance.rooms?.map((e) => e.toJson()).toList(),
};
