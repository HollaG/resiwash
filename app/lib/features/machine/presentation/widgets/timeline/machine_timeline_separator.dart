import 'package:flutter/material.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/event_entity.dart';

class MachineTimelineSeparator extends StatelessWidget {
  final EventEntity event;
  final String? labelTop;
  final String? labelBottom;

  const MachineTimelineSeparator({
    super.key,
    required this.event,
    this.labelTop,
    this.labelBottom,
  });

  @override
  Widget build(BuildContext context) {
    final color = MachineStatusIndicator.getIndicatorColor(
      context,
      event.status,
    );
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (labelTop != null)
            Positioned(
              top: -25,
              left: -35 + 2 / 2, // center the label under the indicator
              child: SizedBox(
                width: 70,
                child: Text(
                  textAlign: TextAlign.center,
                  labelTop!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (labelBottom != null)
            Positioned(
              top: 20,
              left: -35 + 2 / 2, // center the label under the indicator
              child: SizedBox(
                width: 70,
                child: Text(
                  textAlign: TextAlign.center,
                  labelBottom!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          SizedBox(width: 2, height: 16, child: Container(color: color)),
        ],
      ),
    );
  }
}
