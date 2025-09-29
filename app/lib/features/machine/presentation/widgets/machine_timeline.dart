import 'package:flutter/material.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/widgets/timeline/machine_timeline_connector.dart';
import 'package:resiwash/features/machine/presentation/widgets/timeline/machine_timeline_event.dart';
import 'package:resiwash/features/machine/presentation/widgets/timeline/machine_timeline_separator.dart';

class MachineTimeline extends StatelessWidget {
  final MachineEntity machine;
  const MachineTimeline({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    appLog.d('Rendering timeline for machine: ${machine.name}');
    appLog.d('${machine.events}');

    if (machine.events == null || machine.events!.isEmpty) {
      return const Center(child: Text('No events available'));
    }

    final events = machine.events!;
    final List<Widget> elements = _buildTimelineElements(events);

    return SizedBox(
      width: double.infinity,
      height: 64, // Increased height to accommodate labels
      child: Center(
        child: SizedBox(
          height: 64,

          child: Center(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: elements,
              reverse: true,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTimelineElements(List<dynamic> events) {
    final List<Widget> elements = [];

    for (int index = 0; index < events.length; index++) {
      final event = events[index];

      DateTime laterEventTime;
      if (index > 0) {
        laterEventTime = events[index - 1].timestamp;
      } else {
        laterEventTime = DateTime.now(); // Use current time for the first event
      }

      // Calculate time difference and width
      final timeDifference = laterEventTime.difference(event.timestamp);
      final timeInMinutes = timeDifference.inMinutes;

      appLog.d(
        'Time difference: ${timeDifference.inMilliseconds}ms, minutes: $timeInMinutes',
      );

      // Min width = 80px, max width = 150px, 1.5px per minute
      final width = (timeInMinutes * 1.5).clamp(80.0, 150.0);

      // Check if events cross a day boundary
      if (!_isSameDay(laterEventTime, event.timestamp)) {
        // Calculate left and right widths for day boundary crossing
        final startOfEventDay = DateTime(
          event.timestamp.year,
          event.timestamp.month,
          event.timestamp.day,
        );
        final endOfLaterDay = DateTime(
          laterEventTime.year,
          laterEventTime.month,
          laterEventTime.day,
          23,
          59,
          59,
        );

        final msSinceStartOfDay = laterEventTime
            .difference(startOfEventDay)
            .inMinutes;
        final msTillEndOfDay = endOfLaterDay
            .difference(event.timestamp)
            .inMinutes;

        final leftWidth = (msSinceStartOfDay * 1.5).clamp(40.0, 150.0);
        final rightWidth = (msTillEndOfDay * 1.5).clamp(40.0, 150.0);

        // Format date label (e.g., "8 May", "2 June")
        final label = _formatDateLabel(startOfEventDay);

        elements.addAll([
          MachineTimelineConnector(
            key: Key('${index}-1'),
            status: event.status,
            width: leftWidth,
          ),
          MachineTimelineSeparator(
            key: Key('${index}-2'),
            event: event,
            labelTop: label,
          ),
          MachineTimelineConnector(
            key: Key('${index}-3'),
            status: event.status,
            width: rightWidth,
          ),
          MachineTimelineEvent(key: Key('${index}-4'), event: event),
        ]);
      } else {
        // Same day - create duration label
        String? label;
        if (index == 0) {
          label = _formatDurationLabel(timeInMinutes);
        }

        elements.addAll([
          MachineTimelineConnector(
            key: Key('${index}-1'),
            status: event.status,
            width: width,
            label: label,
          ),
          MachineTimelineEvent(key: Key('${index}-2'), event: event),
        ]);
      }
    }

    // current time indicator
    final now = DateTime.now();
    final currentTimeLabel = _formatTimeLabel(now);
    elements.insert(
      0,
      MachineTimelineSeparator(
        event: machine.events![0],
        labelTop: "Now",
        labelBottom: currentTimeLabel,
      ),
    );

    // last event indicator
    final lastEvent = events[events.length - 1];
    final startOfLastEventDay = DateTime(
      lastEvent.timestamp.year,
      lastEvent.timestamp.month,
      lastEvent.timestamp.day,
    );
    final endDateLabel = _formatDateLabel(startOfLastEventDay);

    elements.add(
      MachineTimelineConnector(
        key: const Key('end-connector'),
        status: lastEvent.status,
        width: 50,
      ),
    );
    elements.add(
      MachineTimelineSeparator(
        key: const Key('end'),
        event: lastEvent,
        labelTop: endDateLabel,
      ),
    );

    // finally, add a spacer of 35px at the start and end
    elements.insert(0, SizedBox(width: 35));
    elements.add(SizedBox(width: 35));

    // Add a TimelineSeparator at the start, with the label being "Now"
    // final now = DateTime.now();
    // final currentTimeLabel = _formatTimeLabel(now);
    // elements.add(
    //   MachineTimelineSeparator(
    //     key: const Key('now'),
    //     event: events[0],
    //     labelTop: 'Now',
    //     labelBottom: currentTimeLabel,
    //   ),
    // );

    // // Add a timelineSeparator at the end, with the label being the last event's startOfDay
    // final lastEvent = events[events.length - 1];
    // final startOfLastEventDay = DateTime(
    //   lastEvent.timestamp.year,
    //   lastEvent.timestamp.month,
    //   lastEvent.timestamp.day,
    // );
    // final endDateLabel = _formatDateLabel(startOfLastEventDay);

    // elements.addAll([
    //   MachineTimelineConnector(
    //     key: const Key('end-connector'),
    //     status: lastEvent.status,
    //     width: 50,
    //   ),
    //   MachineTimelineSeparator(
    //     key: const Key('end'),
    //     event: lastEvent,
    //     labelTop: endDateLabel,
    //   ),
    // ]);

    // reverse the elements

    return elements;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatDurationLabel(int timeInMinutes) {
    if (timeInMinutes > 43200) {
      // 30 days
      return '${(timeInMinutes / 43200).floor()}mo';
    } else if (timeInMinutes > 10080) {
      // 7 days
      return '${(timeInMinutes / 10080).floor()}w';
    } else if (timeInMinutes > 1440) {
      // 24 hours
      return '${(timeInMinutes / 1440).floor()}d';
    } else if (timeInMinutes > 60) {
      return '${(timeInMinutes / 60).floor()}h';
    } else {
      return '${timeInMinutes}m';
    }
  }

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
