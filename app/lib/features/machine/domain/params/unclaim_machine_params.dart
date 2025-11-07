import 'package:equatable/equatable.dart';

class UnclaimMachineParams extends Equatable {
  final String fcmToken;

  const UnclaimMachineParams({required this.fcmToken});
  @override
  List<Object?> get props => [fcmToken];

  Map<String, dynamic> toJson() {
    return {'fcmToken': fcmToken};
  }

  @override
  String toString() {
    return 'UnclaimMachineParams(fcmToken: $fcmToken)';
  }

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> queryParams = {};

    queryParams['fcmToken'] = fcmToken;

    return queryParams;
  }
}
