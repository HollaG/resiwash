import 'package:timeago/timeago.dart' as timeago;

/// Utility class for date and time operations
class DateTimeUtils {
  /// Returns a human-readable relative time string (e.g., "2 minutes ago", "3 hours ago")
  ///
  /// If [dateTime] is null, returns null.
  ///
  /// Examples:
  /// - 30 seconds ago → "30 seconds ago"
  /// - 2 minutes ago → "2 minutes ago"
  /// - 3 hours ago → "3 hours ago"
  /// - 2 days ago → "2 days ago"
  static String? formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return timeago.format(dateTime);
  }

  /// Returns a human-readable relative time string with custom locale
  static String? formatRelativeTimeWithLocale(
    DateTime? dateTime,
    String locale,
  ) {
    if (dateTime == null) return null;
    return timeago.format(dateTime, locale: locale);
  }

  /// Returns true if the given DateTime is within the last [minutes] minutes
  static bool isWithinLastMinutes(DateTime? dateTime, int minutes) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return difference.inMinutes <= minutes;
  }

  /// Returns true if the given DateTime is today
  static bool isToday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }
}
