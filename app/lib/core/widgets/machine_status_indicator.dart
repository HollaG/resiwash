import 'package:flutter/material.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/theme.dart';

class MachineStatusIndicator extends StatelessWidget {
  final MachineStatus? status;

  const MachineStatusIndicator({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: _getStatusColor(context),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (status) {
      case MachineStatus.available:
        // Use theme.success color
        return MaterialTheme.success.light.color;
      case MachineStatus.inUse:
        // Use the new inUse color we added
        return MaterialTheme.inUse.light.color;
      case MachineStatus.hasIssues:
        // Use the unknown/tertiary color (495057)
        return const Color(0xff495057);
      case null:
        return const Color(0xff495057);
    }
  }
}
