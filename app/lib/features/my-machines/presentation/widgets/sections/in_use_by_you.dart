import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/demo/machine_row_slidable_explanation.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart'
    as claim_state;
import 'package:resiwash/features/my-machines/presentation/widgets/tracker.dart';

class InUseByYouSection extends StatefulWidget {
  const InUseByYouSection({super.key});

  @override
  State<InUseByYouSection> createState() => _InUseByYouSectionState();
}

class _InUseByYouSectionState extends State<InUseByYouSection> {
  bool isEditingClaimed = false;
  bool canEditClaimed = false;

  Future<int?> _dialogBuilder(BuildContext context) {
    int selectedCycleTime = 30;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.all(12),
              title: const Text('Set cycle time'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 12.0,
                children: [
                  Text(
                    'Please choose your cycle time for the machine you are using.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Center(
                    child: SegmentedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return (Theme.of(context).colorScheme.primary);
                            }
                            return Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).colorScheme.onPrimary;
                            }
                            return Theme.of(context).colorScheme.onSurface;
                          },
                        ),
                      ),
                      segments: const <ButtonSegment<int>>[
                        ButtonSegment<int>(value: 30, label: Text('30m')),
                        ButtonSegment<int>(value: 45, label: Text('45m')),
                        ButtonSegment<int>(value: 60, label: Text('60m')),
                      ],
                      selected: <int>{selectedCycleTime},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          selectedCycleTime = newSelection.first;
                        });
                      },
                    ),
                  ),

                  // Padding(
                  //   padding: const EdgeInsets.fromLTRB(24.0, 0, 24, 0),
                  //   child: Row(
                  //     spacing: 20,
                  //     children: [
                  //       Expanded(child: Divider(), flex: 1),
                  //       Text("or"),
                  //       Expanded(child: Divider(), flex: 1),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Returns null
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Confirm'),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(selectedCycleTime); // Return selected time
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onEditPressed(
    BuildContext context,
    // List<MachineEntity> subscribedMachines,
    // List<String> claimedMachineIds,
  ) {
    if (!mounted) return;

    // toggle isEditing
    setState(() {
      isEditingClaimed = !isEditingClaimed;
    });
    // _dialogBuilder(context).then((selectedCycleTime) {
    // if (selectedCycleTime != null) {
    //   context
    //       .read<MyMachinesCubit>()
    //       .updateClaimedMachineCycleTime(wi, cycleTime)
    // }
    // });
    // show a bottom sheet with a selectable list of machines
    // showModalBottomSheet(
    //   context: context,
    //   builder: (bottomSheetContext) {
    //     return BlocProvider.value(
    //       value: context.read<MyMachinesCubit>(), // reuse existing cubit
    //       child: BlocBuilder<MyMachinesCubit, MyMachinesState>(
    //         builder: (context, state) {
    //           if (state is! MyMachinesLoaded) {
    //             return Center(child: CircularProgressIndicator());
    //           }
    //           final subscribedMachines = state.subscribedMachines ?? [];
    //           final claimedMeta = state.claimedMachineMetadata;
    //           return SizedBox(
    //             width: double.infinity,
    //             height: 500,
    //             child: Container(
    //               padding: const EdgeInsets.all(24.0),
    //               child: Column(
    //                 children: [
    //                   Text(
    //                     'Select machines',
    //                     style: Theme.of(context).textTheme.headlineSmall,
    //                   ),
    //                   // Text("You can also swipe left twice to claim a machine."),
    //                   SizedBox(height: 16),
    //                   Expanded(
    //                     child: ListView(
    //                       children: subscribedMachines
    //                           .map(
    //                             (machine) => CheckboxListTile(
    //                               contentPadding: EdgeInsets.zero,
    //                               title: MachineRow(
    //                                 machine: machine,
    //                                 showIcon: false,
    //                                 allowSwipe: false,
    //                               ),
    //                               value: claimedMeta
    //                                   .map((e) => e.machineId)
    //                                   .contains(machine.machineId),
    //                               onChanged: (newValue) {
    //                                 if (newValue == true) {
    //                                   context
    //                                       .read<MyMachinesCubit>()
    //                                       .claimMachine(machine);
    //                                 } else {
    //                                   context
    //                                       .read<MyMachinesCubit>()
    //                                       .unclaimMachine(machine);
    //                                 }
    //                               },
    //                             ),
    //                           )
    //                           .toList(),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           );
    //         },
    //       ),
    //     );
    //   },
    // );
  }

  // There's no "saving" needed as it is live
  void _onFinishPressed() {
    // toggle isEditing
    setState(() {
      isEditingClaimed = !isEditingClaimed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClaimCubit, claim_state.ClaimState>(
      listener: (context, state) {
        print("debug claim inusebyyou $state");
        // no-op
        if (state is claim_state.ClaimLoaded &&
            state.claimedMachineMetadata.isNotEmpty) {
          setState(() {
            canEditClaimed = true;
          });
        } else {
          setState(() {
            isEditingClaimed = false;
            canEditClaimed = false;
          });
        }
      },
      builder: (context, state) {
        // List of machines in use by the user
        if (state is claim_state.ClaimLoading)
          return Center(child: CircularProgressIndicator());
        if (state is claim_state.ClaimLoaded) {
          // filter out to only have in-use machines
          final inUseMachines = state.claimedMachines!
              .where(
                (machine) =>
                    (machine.currentStatus == MachineStatus.inUse ||
                    machine.currentStatus == MachineStatus.finishing),
              )
              .toList();

          final inUseMetadata = state.claimedMachineMetadata.where(
            (meta) => inUseMachines.any(
              (machine) => machine.machineId == meta.machineId,
            ),
          );
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
                        // Text(
                        //   "Swipe to edit",
                        //   style: Theme.of(context).textTheme.bodySmall,
                        // ),
                      ],
                    ),
                  ),
                ],
              ),

              // claimed machines
              if (inUseMachines.isNotEmpty && inUseMetadata.isNotEmpty)
                Column(
                  spacing: 8,
                  children: inUseMetadata
                      .map(
                        (claimedMeta) => Tracker(
                          showControls: isEditingClaimed,
                          claimedMetadata: claimedMeta,
                          machine: (inUseMachines).firstWhere(
                            (machine) =>
                                machine.machineId == claimedMeta.machineId,
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),

                  child: Column(
                    spacing: 8,
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        "You have not marked any machines as in use. ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        textAlign: TextAlign.center,
                        "Swipe right on a machine, or scan a QR code to mark a machine as in use by you.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      MachineRowSlidableExplanation(
                        initialPeekState: PeekState.left,
                      ),
                    ],
                  ),
                ),
            ],
          );
        }

        return SizedBox.shrink();
      },
    );
  }
}
