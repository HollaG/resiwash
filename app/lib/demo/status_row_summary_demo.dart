import 'package:flutter/material.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';

/// A demonstration widget showing the StatusRowSummary UI structure
/// with 8 hardcoded machines all with unknown status
class StatusRowSummaryDemo extends StatelessWidget {
  final String label;

  const StatusRowSummaryDemo({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    const int totalCount = 3;
    const int availableCount = 0;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        spacing: 10,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 2,
              runSpacing: 2,
              children: List.generate(
                3,
                (index) =>
                    const MachineStatusIndicator(status: MachineStatus.unknown),
              ),
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
