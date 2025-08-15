import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/shared/room/domain/entities/room_entity.dart';

abstract interface class RoomRepository {
  Future<Either<Failure, List<RoomEntity>>> getRooms();
  Future<Either<Failure, RoomEntity>> getRoomById(String areaId, String roomId);
}
