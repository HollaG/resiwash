import 'package:resiwash/core/shared/room/domain/entities/room_entity.dart';

class AreaEntity {
  final int areaId;
  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final String shortName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // optional, only if joined
  final List<RoomEntity>? rooms;

  AreaEntity({
    required this.areaId,
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.shortName,
    required this.createdAt,
    required this.updatedAt,

    this.rooms,
  });
}
