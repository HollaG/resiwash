import 'package:equatable/equatable.dart';
import 'package:resiwash/features/room/domain/entities/room_entity.dart';

sealed class RoomDetailState extends Equatable {
  const RoomDetailState();

  @override
  List<Object?> get props => [];
}

class RoomDetailInitialState extends RoomDetailState {}

class RoomDetailLoading extends RoomDetailState {}

class RoomDetailLoaded extends RoomDetailState {
  final RoomEntity room;
  const RoomDetailLoaded({required this.room});

  @override
  List<Object?> get props => [room];
}

class RoomDetailError extends RoomDetailState {
  final String message;

  const RoomDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
