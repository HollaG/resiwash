import 'package:flutter/material.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/domain/entities/event_entity.dart';

class MachineTimelineEvent extends StatelessWidget {
  final EventEntity event;
  const MachineTimelineEvent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,

        children: [
          MachineStatusIndicator(status: event.status),
          Positioned(
            top: 20,
            left: -35 + 16 / 2, // center the label under the indicator
            child: SizedBox(
              width: 70,
              child: Text(
                textAlign: TextAlign.center,
                _formatTime(event.timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // format the time in HH:mm a
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
