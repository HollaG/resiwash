import 'package:json_annotation/json_annotation.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/event_entity.dart';

part 'event_model.g.dart';

@JsonSerializable()
class EventModel {
  final int eventId;
  final String timestamp;
  final MachineStatus status;
  final double? reading;

  const EventModel({
    required this.eventId,
    required this.timestamp,
    required this.status,
    this.reading,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);
  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  EventEntity toEntity() {
    return EventEntity(
      eventId: eventId,
      timestamp: DateTime.parse(timestamp),
      status: status,
      reading: reading,
    );
  }

  @override
  String toString() {
    return 'EventModel(eventId: $eventId, timestamp: $timestamp, status: $status, reading: $reading)';
  }
}
