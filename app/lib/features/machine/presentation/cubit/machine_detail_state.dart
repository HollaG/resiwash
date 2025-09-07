import 'package:equatable/equatable.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

sealed class MachineDetailState extends Equatable {
  const MachineDetailState();

  @override
  List<Object?> get props => [];
}

class MachineDetailInitial extends MachineDetailState {
  const MachineDetailInitial();
}

class MachineDetailLoading extends MachineDetailState {
  const MachineDetailLoading();
}

class MachineDetailLoaded extends MachineDetailState {
  final MachineEntity machine;

  const MachineDetailLoaded(this.machine);

  @override
  List<Object?> get props => [machine];
}

class MachineDetailError extends MachineDetailState {
  final String message;

  const MachineDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
