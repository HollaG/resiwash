import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_state.dart';

class RoomDetailCubit extends Cubit<RoomDetailState> {
  GetRoomUsecase getRoomUsecase;

  RoomDetailCubit({required this.getRoomUsecase})
    : super(RoomDetailInitialState());

  Future<void> load({required String roomId}) async {
    emit(RoomDetailLoading());
    final room = await getRoomUsecase.call(roomId: roomId);

    room.fold(
      (err) => emit(RoomDetailError("Failed to load room $roomId")),
      (room) => emit(RoomDetailLoaded(room: room)),
    );
  }
}
