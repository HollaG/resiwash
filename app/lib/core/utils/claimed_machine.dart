import 'dart:convert';

class ClaimedMachineMetadata {
  final String machineId;
  final int cycleTime;

  ClaimedMachineMetadata({required this.machineId, required this.cycleTime});

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {'machineId': machineId, 'cycleTime': cycleTime};
  }

  // Create from JSON
  factory ClaimedMachineMetadata.fromJson(Map<String, dynamic> json) {
    return ClaimedMachineMetadata(
      machineId: json['machineId'] as String,
      cycleTime: json['cycleTime'] as int,
    );
  }

  // Encode to string for storage
  String encode() => jsonEncode(toJson());

  // Decode from string
  static ClaimedMachineMetadata decode(String jsonString) {
    return ClaimedMachineMetadata.fromJson(jsonDecode(jsonString));
  }

  @override
  String toString() =>
      'ClaimedMachine(machineId: $machineId, cycleTime: $cycleTime)';
}
