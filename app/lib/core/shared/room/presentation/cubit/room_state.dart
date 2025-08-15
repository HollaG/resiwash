import 'package:resiwash/core/shared/room/domain/entities/room_entity.dart';

sealed class RoomState {
  RoomState();
}

class RoomInitialState extends RoomState {
  RoomInitialState();
}

class RoomLoading extends RoomState {
  RoomLoading();
}

class RoomLoaded extends RoomState {
  RoomEntity room;
  RoomLoaded({required this.room});
}

class RoomError extends RoomState {
  RoomError();
}
