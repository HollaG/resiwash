import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/room/domain/entities/room_entity.dart';
import 'package:resiwash/features/room/domain/repositories/room_repository.dart';

class GetRoomUsecase {
  final RoomRepository repository;

  GetRoomUsecase({required this.repository});
  Future<Either<Failure, RoomEntity>> call({required String roomId}) {
    return repository.getRoomById(roomId: roomId);
  }
}
