// data/models/room_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:resiwash/core/shared/room/domain/entities/room_entity.dart';
import 'package:resiwash/core/shared/area/data/models/area_model.dart';

part 'room_model.g.dart';

@JsonSerializable(explicitToJson: true)
class RoomModel {
  final int roomId;
  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final String shortName;

  final AreaModel? area;
  final List<Map<String, dynamic>>? machines;
  final List<Map<String, dynamic>>? sensors;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RoomModel({
    required this.roomId,
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.shortName,
    this.area,
    this.machines,
    this.sensors,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);
  Map<String, dynamic> toJson() => _$RoomModelToJson(this);

  RoomEntity toEntity() => RoomEntity(
    roomId: roomId,
    name: name,
    location: location,
    description: description,
    imageUrl: imageUrl,
    shortName: shortName,
    area: area?.toEntity(),
    machines: machines,
    sensors: sensors,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
