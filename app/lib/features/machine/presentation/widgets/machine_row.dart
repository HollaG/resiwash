import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/router.dart';

class MachineRow extends StatelessWidget {
  final MachineEntity machine;

  const MachineRow({Key? key, required this.machine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the utility function to generate the complete subtitle
    final location = MachineDisplayUtils.getLocationLabel(machine);
    final time = MachineDisplayUtils.getStatusLabel(machine);

    return ListTile(
      onTap: () {
        // go to /machines/:id
        context.push(
          Uri(
            path: AppRoutes.buildMachineDetailRoute(machine.machineId),
          ).toString(),
          extra: {'machine': machine},
        );
      },
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Text(machine.name, style: Theme.of(context).textTheme.labelMedium),
          Text(
            "@ $location",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      subtitle: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(time)],
      ),
      trailing: machine.type == MachineType.washer
          ? AssetIcons.washerIcon(context)
          : AssetIcons.dryerIcon(context),
      leading: MachineStatusIndicator(status: machine.currentStatus),
    );
  }
}
