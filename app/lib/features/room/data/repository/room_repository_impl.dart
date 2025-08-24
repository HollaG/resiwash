import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/room/data/datasource/room_remote_datasource.dart';
import 'package:resiwash/features/room/domain/entities/room_entity.dart';
import 'package:resiwash/features/room/domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  RoomRemoteDatasource dataSource;
  RoomRepositoryImpl({required this.dataSource});
  @override
  Future<Either<Failure, List<RoomEntity>>> getRooms() {
    // TODO: implement getRooms
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, RoomEntity>> getRoomById({
    required String roomId,
  }) async {
    try {
      final room = await dataSource.getRoomById(roomId: roomId);
      return Right(room);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      return Left(Failure());
    }
  }
}
