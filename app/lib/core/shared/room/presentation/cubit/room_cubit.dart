import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/shared/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/core/shared/room/presentation/cubit/room_state.dart';

class RoomCubit extends Cubit<RoomState> {
  GetRoomUsecase getRoomUsecase;

  RoomCubit({required this.getRoomUsecase}) : super(RoomInitialState());

  Future<void> getRoom(String areaId, String roomId) async {
    emit(RoomLoading());
    final room = await getRoomUsecase.call(areaId, roomId);

    room.fold(
      (err) => emit(RoomError()),
      (room) => emit(RoomLoaded(room: room)),
    );
  }
}
