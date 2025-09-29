import 'package:flutter/material.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';

// Timeline connector that draws a colored line with optional label
class MachineTimelineConnector extends StatelessWidget {
  final MachineStatus status;
  final double? width;
  final String? label;
  final double height;

  const MachineTimelineConnector({
    super.key,
    required this.status,
    this.width,
    this.label,
    this.height = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForMachineStatus(context, status);

    return Center(
      child: Stack(
        clipBehavior: Clip.none,

        children: [
          // connector item
          Container(
            height: 16,
            child: Center(
              child: SizedBox(
                width: width, // todo: set based on time,
                height: 2,
                child: Container(color: color),
              ),
            ),
          ),
          if (label != null)
            Positioned(
              top: 10,
              // left: -35,
              left: 0,
              right: 0,
              child: SizedBox(
                width: 70,
                child: Text(
                  textAlign: TextAlign.center,
                  label!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          // Positioned.fill(
          //   // top: 5,
          //   // left: -35,
          //   child: Align(
          //     alignment: Alignment.center,
          //     child: SizedBox(
          //       width: 70,
          //       child: Text(
          //         textAlign: TextAlign.center,
          //         label!,
          //         style: Theme.of(context).textTheme.labelSmall?.copyWith(
          //           color: Theme.of(context).colorScheme.onSurfaceVariant,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );

    // return Column(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     Container(
    //       width: width ?? 50.0,
    //       height: height,
    //       decoration: BoxDecoration(
    //         color: color,
    //         borderRadius: BorderRadius.circular(height / 2),
    //       ),
    //     ),
    //     if (label != null) ...[
    //       const SizedBox(height: 4),
    //       Text(
    //         label!,
    //         style: Theme.of(context).textTheme.labelSmall?.copyWith(
    //           color: Theme.of(context).colorScheme.onSurfaceVariant,
    //         ),
    //       ),
    //     ],
    //   ],
    // );
  }

  Color _getColorForMachineStatus(BuildContext context, MachineStatus status) {
    return MachineStatusIndicator.getIndicatorColor(context, status);
  }
}
