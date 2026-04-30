import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/claim_entity.dart';

class ClaimModel {
  final int claimId;
  final String? fcmToken;
  final int cycleTime;
  final int machineId;
  final MachineModel? machine;
  final DateTime claimedAt;

  ClaimModel({
    required this.claimId,
    this.fcmToken,
    required this.cycleTime,
    required this.machineId,
    this.machine,
    required this.claimedAt,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      claimId: json['claimId'] as int,
      fcmToken: json['fcmToken'] as String?,
      cycleTime: json['cycleTime'] as int,
      machineId: json['machineId'] as int,
      machine: json['machine'] != null
          ? MachineModel.fromJson(json['machine'] as Map<String, dynamic>)
          : null,
      claimedAt: DateTime.parse(json['claimedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'claimId': claimId,
      'fcmToken': fcmToken,
      'cycleTime': cycleTime,
      'machineId': machineId,
      'machine': machine?.toJson(),
      'claimedAt': claimedAt.toIso8601String(),
    };
  }

  ClaimEntity toEntity() {
    return ClaimEntity(
      claimId: claimId,
      fcmToken: fcmToken,
      cycleTime: cycleTime,
      machineId: machineId,
      claimedAt: claimedAt,
      machine: machine?.toEntity(),
    );
  }
}
