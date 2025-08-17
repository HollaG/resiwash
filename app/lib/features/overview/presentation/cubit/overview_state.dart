import 'package:resiwash/core/shared/machine/domain/entities/machine_entity.dart';
import 'package:equatable/equatable.dart';

sealed class OverviewState extends Equatable {
  const OverviewState();

  @override
  List<Object?> get props => [];
}

class OverviewInitial extends OverviewState {}

class OverviewLoading extends OverviewState {}

class OverviewLoaded extends OverviewState {
  final List<MachineEntity> machines;
  final Map<String, List<MachineEntity>> machinesByRoom; // UI-specific grouping

  List<MachineEntity> getMachinesInRoom(String roomId) {
    return machinesByRoom[roomId] ?? [];
  }

  const OverviewLoaded({required this.machines, required this.machinesByRoom});
}

class OverviewError extends OverviewState {
  final String message;

  const OverviewError(this.message);
}
