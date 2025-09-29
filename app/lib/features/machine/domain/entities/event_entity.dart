import 'package:equatable/equatable.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';

class EventEntity extends Equatable {
  final int eventId;
  final DateTime timestamp;
  final MachineStatus status;
  final double? reading;

  const EventEntity({
    required this.eventId,
    required this.timestamp,
    required this.status,
    this.reading,
  });

  @override
  List<Object?> get props => [eventId, timestamp, status, reading];

  @override
  String toString() {
    return 'EventEntity(eventId: $eventId, timestamp: $timestamp, status: $status, reading: $reading)';
  }

  /// Creates a copy with updated parameters
  EventEntity copyWith({
    int? eventId,
    DateTime? timestamp,
    MachineStatus? status,
    double? reading,
  }) {
    return EventEntity(
      eventId: eventId ?? this.eventId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      reading: reading ?? this.reading,
    );
  }
}
