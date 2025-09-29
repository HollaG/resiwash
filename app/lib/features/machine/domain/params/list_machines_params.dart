import 'package:equatable/equatable.dart';

class ListMachinesParams extends Equatable {
  final bool? min;
  final List<String>? areaIds;
  final List<String>? roomIds;
  final List<String>? machineIds;
  final bool? extra;

  const ListMachinesParams({
    this.min,
    this.areaIds,
    this.roomIds,
    this.machineIds,
    this.extra,
  });

  @override
  List<Object?> get props => [min, areaIds, roomIds, machineIds, extra];

  Map<String, dynamic> toJson() {
    return {
      if (min != null) 'min': min,
      if (areaIds != null) 'areaIds': areaIds,
      if (roomIds != null) 'roomIds': roomIds,
      if (machineIds != null) 'machineIds': machineIds,
      if (extra != null) 'extra': extra,
    };
  }

  /// Creates a copy with updated parameters
  ListMachinesParams copyWith({
    bool? min,
    List<String>? areaIds,
    List<String>? roomIds,
    List<String>? machineIds,
    bool? extra,
  }) {
    return ListMachinesParams(
      min: min ?? this.min,
      areaIds: areaIds ?? this.areaIds,
      roomIds: roomIds ?? this.roomIds,
      machineIds: machineIds ?? this.machineIds,
      extra: extra ?? this.extra,
    );
  }

  @override
  String toString() {
    return 'ListMachinesParams(min: $min, areaIds: $areaIds, roomIds: $roomIds, machineIds: $machineIds, extra: $extra)';
  }

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> queryParams = {};
    if (min != null) queryParams['min'] = min;
    if (extra != null) queryParams['extra'] = extra;
    if (areaIds != null && areaIds!.isNotEmpty) {
      queryParams['areaIds[]'] = areaIds;
    }
    if (roomIds != null && roomIds!.isNotEmpty) {
      queryParams['roomIds[]'] = roomIds;
    }
    if (machineIds != null && machineIds!.isNotEmpty) {
      queryParams['machineIds[]'] = machineIds;
    }
    return queryParams;
  }
}
