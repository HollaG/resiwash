import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_state.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/tracker.dart';

class InUseByYouSection extends StatelessWidget {
  const InUseByYouSection({super.key});

  void _onEditPressed(
    BuildContext context,
    // List<MachineEntity> subscribedMachines,
    // List<String> claimedMachineIds,
  ) {
    // show a bottom sheet with a selectable list of machines
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<MyMachinesCubit>(), // reuse existing cubit
          child: BlocBuilder<MyMachinesCubit, MyMachinesState>(
            builder: (context, state) {
              if (state is! MyMachinesLoaded) {
                return Center(child: CircularProgressIndicator());
              }
              final subscribedMachines = state.subscribedMachines ?? [];
              final claimedMeta = state.claimedMachineMetadata;
              return SizedBox(
                width: double.infinity,
                height: 500,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Select machines',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      // Text("You can also swipe left twice to claim a machine."),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: subscribedMachines
                              .map(
                                (machine) => CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: MachineRow(
                                    machine: machine,
                                    showIcon: false,
                                    allowSwipe: false,
                                  ),
                                  value: claimedMeta
                                      .map((e) => e.machineId)
                                      .contains(machine.machineId),
                                  onChanged: (newValue) {
                                    if (newValue == true) {
                                      context
                                          .read<MyMachinesCubit>()
                                          .claimMachine(machine);
                                    } else {
                                      context
                                          .read<MyMachinesCubit>()
                                          .unclaimMachine(machine);
                                    }
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyMachinesCubit, MyMachinesState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 12,

          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "In use by you",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      RichText(
                        text: TextSpan(
                          text: "Set an ",
                          style: Theme.of(context).textTheme.bodySmall,
                          children: [
                            TextSpan(
                              text: "always-visible ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  "notification for machines you are currently using.",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    if (state is! MyMachinesLoaded) return;
                    _onEditPressed(context);
                  },
                  label: Text("Edit"),
                  icon: Icon(Icons.edit),
                ),
                // IconButton(onPressed: () {}, icon: Icon(Icons.add)),
              ],
            ),

            // List of machines in use by the user
            if (state is MyMachinesLoading)
              Center(child: CircularProgressIndicator()),

            // claimed machines
            if (state is MyMachinesLoaded &&
                state.claimedMachines.isNotEmpty &&
                state.claimedMachineMetadata.isNotEmpty)
              Column(
                spacing: 8,
                children: state.claimedMachineMetadata.isNotEmpty
                    ? state.claimedMachineMetadata
                          .map(
                            (claimedMeta) => Tracker(
                              claimedMetadata: claimedMeta,
                              machine: (state.claimedMachines).firstWhere(
                                (machine) =>
                                    machine.machineId == claimedMeta.machineId,
                              ),
                            ),
                          )
                          .toList()
                    : [
                        Text(
                          "You have not marked any machines as in use.",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
              ),
          ],
        );
      },
    );
  }
}
