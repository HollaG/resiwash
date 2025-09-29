import 'package:equatable/equatable.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';

sealed class AreaDetailState extends Equatable {
  const AreaDetailState();

  @override
  List<Object?> get props => [];
}

class AreaDetailInitial extends AreaDetailState {}

class AreaDetailLoading extends AreaDetailState {}

class AreaDetailLoaded extends AreaDetailState {
  final AreaEntity area;

  const AreaDetailLoaded({required this.area});

  @override
  List<Object?> get props => [area];
}

class AreaDetailError extends AreaDetailState {
  final String message;

  const AreaDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
