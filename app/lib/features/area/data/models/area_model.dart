import 'package:json_annotation/json_annotation.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/core/shared/room/data/models/room_model.dart';

part 'area_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AreaModel {
  final int areaId;
  final String name;
  final String? location;
  final String? description;
  final String? imageUrl;
  final String? shortName;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Use RoomModel here (NOT RoomEntity)
  final List<RoomModel>? rooms;

  const AreaModel({
    required this.areaId,
    required this.name,
    this.location,
    this.description,
    this.imageUrl,
    this.shortName,
    required this.createdAt,
    required this.updatedAt,
    this.rooms,
  });

  // JSON
  factory AreaModel.fromJson(Map<String, dynamic> json) =>
      _$AreaModelFromJson(json);

  Map<String, dynamic> toJson() => _$AreaModelToJson(this);

  // Domain mapping
  AreaEntity toEntity() => AreaEntity(
    areaId: areaId,
    name: name,
    location: location,
    description: description,
    imageUrl: imageUrl,
    shortName: shortName,
    createdAt: createdAt,
    updatedAt: updatedAt,
    rooms: rooms?.map((r) => r.toEntity()).toList(),
  );

  /// Optional: convenience to go the other way when needed
  // static AreaModel fromEntity(AreaEntity e) => AreaModel(
  //       areaId: e.areaId,
  //       name: e.name,
  //       location: e.location,
  //       description: e.description,
  //       imageUrl: e.imageUrl,
  //       shortName: e.shortName,
  //       createdAt: e.createdAt,
  //       updatedAt: e.updatedAt,
  //       rooms: e.rooms?.map(RoomModel.fromEntity).toList(),
  //     );
}
