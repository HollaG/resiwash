import 'package:flutter/material.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/theme.dart';

class Tracker extends StatelessWidget {
  final MachineEntity machine;
  final ClaimedMachineMetadata claimedMetadata;

  const Tracker({
    super.key,
    required this.machine,
    required this.claimedMetadata,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.accent.colorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // top widget
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine.name,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        "${machine.room?.name} @ ${machine.room?.area?.shortName}",
                      ),
                    ],
                  ),
                ),
                machine.type == MachineType.washer
                    ? AssetIcons.washerIcon(context)
                    : AssetIcons.dryerIcon(context),
              ],
            ),
          ),

          // todo
          SizedBox(height: 16),
          Row(
            spacing: 24,
            children: [
              Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: 40 / 100,
                        strokeAlign: -1,
                        strokeWidth: 16,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                    ),
                  ),

                  SizedBox(
                    width: 96,
                    height: 96,

                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96.0,
                    height: 96.0,

                    child: Center(
                      child: Container(
                        width: 96 - 16 * 2 - 2,
                        height: 96 - 16 * 2 - 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              // color: Colors.black.withOpacity(0.25),
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "40%",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  // cycle indicator
                  Row(
                    spacing: 4,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      Text(
                        "30 minute cycle",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  // time left
                  RichText(
                    text: TextSpan(
                      text: "15 min 30 sec",
                      style: Theme.of(context).textTheme.headlineSmall,
                      children: <TextSpan>[
                        TextSpan(
                          text: " left",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),

                  // time since started
                  Text(
                    "Started 10 min 24 sec ago",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
