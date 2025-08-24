import 'package:equatable/equatable.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

sealed class MachineListState extends Equatable {
  const MachineListState();

  @override
  List<Object?> get props => [];
}

class MachineListInitial extends MachineListState {
  const MachineListInitial();
}

class MachineListLoading extends MachineListState {
  const MachineListLoading();
}

class MachineListLoaded extends MachineListState {
  final List<MachineEntity> machines;

  const MachineListLoaded(this.machines);

  @override
  List<Object?> get props => [machines];
}

class MachineListError extends MachineListState {
  final String message;

  const MachineListError(this.message);

  @override
  List<Object?> get props => [message];
}
