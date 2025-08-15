import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/shared/room/domain/entities/room_entity.dart';
import 'package:resiwash/core/shared/room/domain/repositories/room_repository.dart';

class GetRoomUsecase {
  final RoomRepository repository;

  GetRoomUsecase({required this.repository});
  Future<Either<Failure, RoomEntity>> call(String areaId, String roomId) {
    return repository.getRoomById(areaId, roomId);
  }
}
