import 'package:flutter/material.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

class StatusRowSummary extends StatelessWidget {
  // a subset of machines to display
  final List<MachineEntity> machines;
  final String label;

  const StatusRowSummary({required this.label, required this.machines});

  @override
  Widget build(BuildContext context) {
    int totalCount = machines.length;
    int availableCount = machines
        .where((machine) => machine.currentStatus == MachineStatus.available)
        .length;

    int width = (16 + 2) * totalCount;
    // if width > (16 + 2) * 8, find the first divisor of totalCount that is <= 8
    if (width > (16 + 2) * 8) {
      for (int i = 8; i >= 1; i--) {
        if (totalCount % i == 0) {
          width = (16 + 2) * i;
          break;
        }
      }
    }

    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        spacing: 10,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          // Spacer(),
          Flexible(child: Container()),
          SizedBox(
            // hardcode the size of the status indicator box
            width: width.toDouble(),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 2,
              runSpacing: 2,

              children: machines
                  .map(
                    (machine) =>
                        MachineStatusIndicator(status: machine.currentStatus),
                  )
                  .toList(),
            ),
          ),
          Text(
            "$availableCount/$totalCount",
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
