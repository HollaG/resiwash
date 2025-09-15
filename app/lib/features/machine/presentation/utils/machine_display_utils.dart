import 'package:resiwash/core/utils/datetime_utils.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';

/// Utility class for machine-related formatting and display logic
class MachineDisplayUtils {
  /// Generates a descriptive status label for a machine including relative time
  ///
  /// Examples:
  /// - "Available since 2 minutes ago"
  /// - "In use for 30 seconds"
  /// - "Available" (if no lastChangeTime)
  /// - "Has issues" (regardless of time)
  ///
  ///

  static String getStatusLabel(MachineEntity machine) {
    final status = machine.currentStatus;
    final lastChangeTime = machine.lastChangeTime;

    String timePart = '';
    if (lastChangeTime != null) {
      final relativeTime = DateTimeUtils.formatRelativeTime(
        machine.lastChangeTime,
      );
      if (status == MachineStatus.available) {
        timePart = ' since $relativeTime';
      } else if (status == MachineStatus.inUse) {
        timePart = ' for $relativeTime';
      }
    }

    switch (status) {
      case MachineStatus.available:
        return 'Available$timePart';
      case MachineStatus.inUse:
        // replace the " ago"
        return 'In use${timePart.replaceFirst(" ago", "")}';
      case MachineStatus.hasIssues:
        return 'Has issues';
      case null:
        return 'Unknown status';
      default:
        return 'Unknown status';
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

  static String getLabel(MachineEntity machine) {
    return machine.label.isEmpty ? 'Unknown label' : machine.label;
  }

  static String getType(MachineEntity machine) {
    switch (machine.type) {
      case MachineType.washer:
        return 'Washer';
      case MachineType.dryer:
        return 'Dryer';
      case MachineType.unknown:
      default:
        return 'Unknown type';
    }
  }

  static String getLastUpdatedLabel(MachineEntity machine) {
    if (machine.lastUpdated == null) {
      return 'Unknown';
    }

    // return the date in:
    // dd MMM yyyy, HH:mm:ss
    // return DateTimeUtils.formatDateTime(machine.lastUpdated!) ?? 'Unknown';
    return DateTimeUtils.formatReadableDate(machine.lastUpdated!);

    // return DateTimeUtils.formatRelativeTime(machine.lastUpdated) ?? 'Unknown';
  }
}
