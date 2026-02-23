import 'package:flutter/material.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';

class MachineDefaultCycle extends StatefulWidget {
  final MachineType machineType;

  const MachineDefaultCycle({super.key, required this.machineType});

  @override
  State<MachineDefaultCycle> createState() => _MachineDefaultCycleState();
}

class _MachineDefaultCycleState extends State<MachineDefaultCycle> {
  bool hasSetDefault = false;
  int selectedCycleTime = 30; // in minutes, default to 0 (no preference)

  @override
  void initState() {
    super.initState();

    int? currentCycleTime = sl<SharedPreferencesService>()
        .getPreferredCycleTime(widget.machineType);
    setState(() {
      hasSetDefault = currentCycleTime != null;
      selectedCycleTime = currentCycleTime ?? 30;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<int> cycleTimes = [30, 45, 60];
    if (widget.machineType == MachineType.washer) {
      cycleTimes = [30, 32, 34];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        // Row(
        //   children: [
        //     Expanded(
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Text(
        //             "Default Cycle Time (${MachineDisplayUtils.getTypeFromEnum(machineType)})",
        //             style: Theme.of(context).textTheme.headlineSmall,
        //           ),
        //           RichText(
        //             text: TextSpan(
        //               text: "Coming soon",
        //               style: Theme.of(context).textTheme.bodySmall,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //     const SizedBox(width: 8),

        //     // OutlinedButton.icon(
        //     //   onPressed: () {},
        //     //   label: Text("Edit"),
        //     //   icon: Icon(Icons.edit),
        //     // ),
        //     // IconButton(onPressed: () {}, icon: Icon(Icons.add)),
        //   ],
        // ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: hasSetDefault,
          onChanged: (value) {
            setState(() {
              hasSetDefault = value;
              if (!value) {
                sl<SharedPreferencesService>().clearPreferredCycleTime(
                  widget.machineType,
                );
              } else {
                sl<SharedPreferencesService>().setPreferredCycleTime(
                  widget.machineType,
                  selectedCycleTime,
                );
              }
            });
          },

          title: Text(
            "Set default cycle time for ${MachineDisplayUtils.getTypeFromEnum(widget.machineType)}",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          subtitle: Text("Bypass the cycle time selection screen"),
        ),

        AnimatedSize(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,

          child: hasSetDefault
              ? Center(
                  child: SegmentedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return (Theme.of(context).colorScheme.primary);
                        }
                        return Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).colorScheme.onPrimary;
                        }
                        return Theme.of(context).colorScheme.onSurface;
                      }),
                    ),
                    segments: <ButtonSegment<int>>[
                      for (int cycleTime in cycleTimes)
                        ButtonSegment<int>(
                          value: cycleTime,
                          label: Text('${cycleTime}m'),
                        ),
                    ],
                    selected: <int>{selectedCycleTime},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        selectedCycleTime = newSelection.first;
                      });
                    },
                  ),
                )
              : Center(),
        ),
      ],
    );
  }
}
