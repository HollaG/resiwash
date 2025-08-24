import 'package:flutter/material.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

class MachineRow extends StatelessWidget {
  final MachineEntity machine;

  const MachineRow({Key? key, required this.machine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(machine.name, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text("Room here TODO"),
      trailing: machine.type == MachineType.washer
          ? AssetIcons.washerIcon(context)
          : AssetIcons.dryerIcon(context),
      leading: MachineStatusIndicator(status: machine.currentStatus),
    );
  }
}
