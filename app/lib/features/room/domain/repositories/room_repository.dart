import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/room/domain/entities/room_entity.dart';

abstract interface class RoomRepository {
  Future<Either<Failure, List<RoomEntity>>> getRooms();
  Future<Either<Failure, RoomEntity>> getRoomById({required String roomId});
}
