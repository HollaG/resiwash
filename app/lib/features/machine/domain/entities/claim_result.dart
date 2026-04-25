class ClaimResult {
  final String machineId;
  final String machineName;
  final String machineRoomName;
  final String machineType;
  final int secondsTillCompletion;
  final String title;
  final String message;

  const ClaimResult({
    required this.machineId,
    required this.machineName,
    required this.machineRoomName,
    required this.machineType,
    required this.secondsTillCompletion,
    required this.title,
    required this.message,
  });

  // TODO: explain why this must have `data` in it.
  factory ClaimResult.fromJson(Map<String, dynamic> json) {
    return ClaimResult(
      machineId: (json['machineId'] ?? '').toString(),
      machineName: (json['machineName'] ?? '').toString(),
      machineRoomName: (json['machineRoomName'] ?? '').toString(),
      machineType: (json['machineType'] ?? '').toString(),
      secondsTillCompletion: _asInt(json['secondsTillCompletion']),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
