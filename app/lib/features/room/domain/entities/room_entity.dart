import 'package:resiwash/features/area/domain/entities/area_entity.dart';

class RoomEntity {
  final String roomId;
  final String name;
  final String? location;
  final String? description;
  final String? imageUrl;
  final String? shortName;

  // If you have the Area model, keep this as Area? and import it.
  // Otherwise, change to Map<String, dynamic>?.
  final AreaEntity? area;

  // Replace with List<Machine> / List<Sensor> when you have those models.
  final List<Map<String, dynamic>>? machines;
  final List<Map<String, dynamic>>? sensors;

  final DateTime createdAt;
  final DateTime updatedAt;

  RoomEntity({
    required this.roomId,
    required this.name,
    this.location,
    this.description,
    this.imageUrl,
    this.shortName,
    this.area,
    this.machines,
    this.sensors,
    required this.createdAt,
    required this.updatedAt,
  });
}
