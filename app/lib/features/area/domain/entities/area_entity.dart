import 'package:resiwash/core/shared/room/domain/entities/room_entity.dart';

class AreaEntity {
  final String areaId;
  final String name;
  final String? location;
  final String? description;
  final String? imageUrl;
  final String? shortName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // optional, only if joined
  final List<RoomEntity>? rooms;

  AreaEntity({
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
}
