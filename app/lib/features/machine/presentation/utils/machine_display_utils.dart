import 'package:resiwash/core/utils/datetime_utils.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';

/// Utility class for machine-related formatting and display logic
class MachineDisplayUtils {
  /// Generates a descriptive status label for a machine including relative time
  ///
  /// Examples:
  /// - "Available since 2 minutes ago"
  /// - "In use since 30 seconds ago"
  /// - "Available" (if no lastChangeTime)
  /// - "Has issues" (regardless of time)
  static String getStatusLabel(MachineEntity machine) {
    final relativeTime = DateTimeUtils.formatRelativeTime(
      machine.lastChangeTime,
    );

    switch (machine.currentStatus) {
      case MachineStatus.available:
        return relativeTime != null
            ? 'Available since $relativeTime'
            : 'Available';

      case MachineStatus.inUse:
        return relativeTime != null ? 'In use since $relativeTime' : 'In use';

      case MachineStatus.finishing:
        return relativeTime != null
            ? 'Finishing since $relativeTime'
            : 'Finishing';

      case MachineStatus.hasIssues:
        return 'Has issues';

      case MachineStatus.unknown:
      case null:
        return 'Status unknown';
    }
  }

  /// Generates a location label for a machine
  ///
  /// Examples:
  /// - "A1 Laundry Room" (with area shortName and room name)
  /// - "Laundry Room" (room name only)
  /// - "A1" (area shortName only)
  /// - "No room" (fallback)
  static String getLocationLabel(MachineEntity machine) {
    final areaName = machine.room?.area?.shortName;
    final roomName = machine.room?.name;

    if (areaName != null && roomName != null) {
      return '$areaName $roomName';
    } else if (roomName != null) {
      return roomName;
    } else if (areaName != null) {
      return areaName;
    } else {
      return 'No room';
    }
  }

  /// Generates a complete subtitle for a machine row
  ///
  /// Combines location and status information
  /// Example: "A1 Laundry Room • Available since 2 minutes ago"
  static String getSubtitleLabel(MachineEntity machine) {
    final location = getLocationLabel(machine);
    final status = getStatusLabel(machine);
    return '$location\n$status';
  }
}
