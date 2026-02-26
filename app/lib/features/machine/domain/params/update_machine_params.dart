import 'package:equatable/equatable.dart';

class UpdateClaimParams extends Equatable {
  final String fcmToken;
  final int cycleTime;

  const UpdateClaimParams({required this.fcmToken, required this.cycleTime});
  @override
  List<Object?> get props => [fcmToken, cycleTime];

  Map<String, dynamic> toJson() {
    return {'fcmToken': fcmToken, 'cycleTime': cycleTime};
  }

  @override
  String toString() {
    return 'UpdateClaimParams(fcmToken: $fcmToken, cycleTime: $cycleTime)';
  }

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> queryParams = {};

    queryParams['fcmToken'] = fcmToken;
    queryParams['cycleTime'] = cycleTime;

    return queryParams;
  }
}
