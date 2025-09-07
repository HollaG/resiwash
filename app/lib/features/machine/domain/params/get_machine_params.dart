import 'package:equatable/equatable.dart';

class GetMachineParams extends Equatable {
  final bool? extra;

  const GetMachineParams({this.extra});

  @override
  List<Object?> get props => [extra];

  Map<String, dynamic> toJson() {
    return {if (extra != null) 'extra': extra};
  }

  /// Creates a copy with updated parameters
  GetMachineParams copyWith({
    bool? min,
    List<String>? areaIds,
    List<String>? roomIds,
    List<String>? machineIds,
    bool? extra,
  }) {
    return GetMachineParams(extra: extra ?? this.extra);
  }

  @override
  String toString() {
    return 'GetMachineParams(extra: $extra)';
  }

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> queryParams = {};

    if (extra != null) queryParams['extra'] = extra;

    return queryParams;
  }
}
