// TODO:: work in progress
import 'package:equatable/equatable.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';

sealed class AreaState extends Equatable {
  const AreaState();

  @override
  List<Object?> get props => [];
}

class AreaInitial extends AreaState {}

class AreaLoading extends AreaState {}

class AreaLoaded extends AreaState {
  final List<AreaEntity> areas;

  const AreaLoaded({required this.areas});

  @override
  List<Object?> get props => [areas];
}

class AreaError extends AreaState {
  final String message;

  const AreaError(this.message);

  @override
  List<Object?> get props => [message];
}
