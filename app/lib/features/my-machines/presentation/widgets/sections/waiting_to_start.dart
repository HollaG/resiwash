import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/demo/machine_row_slidable_explanation.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart'
    as claim_state;
import 'package:resiwash/features/my-machines/presentation/widgets/trackers/tracker_waiting_to_start.dart';

class WaitingToStartSection extends StatefulWidget {
  const WaitingToStartSection({super.key});

  @override
  State<WaitingToStartSection> createState() => _WaitingToStartSectionState();
}

class _WaitingToStartSectionState extends State<WaitingToStartSection> {
  bool isEditingClaimed = false;
  bool canEditClaimed = false;

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
          // filter out to only have claimed machines that haven't started machines
          final waitingToStartMachines = state.claimedMachines!
              .where(
                (machine) =>
                    machine.currentStatus ==
                    MachineStatus
                        .available, // special case: claimedMachine + available = not started,
              )
              .toList();

          final waitingToStartMeta = state.claimedMachineMetadata.where(
            (meta) => waitingToStartMachines.any(
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
                          "Waiting to start",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        RichText(
                          text: TextSpan(
                            text:
                                "Your machine has not started yet! Please remember to start it.",
                            style: Theme.of(context).textTheme.bodySmall,
                            children: [
                              TextSpan(
                                text:
                                    " If you've just started it, updates may take up to 30 seconds to reflect.",
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // claimed machines
              if (waitingToStartMachines.isNotEmpty &&
                  waitingToStartMeta.isNotEmpty)
                Column(
                  spacing: 8,
                  children: waitingToStartMeta
                      .map(
                        (claimedMeta) => TrackerWaitingToStart(
                          showControls: isEditingClaimed,
                          claimedMetadata: claimedMeta,
                          machine: (waitingToStartMachines).firstWhere(
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
                        "You have not claimed any machines yet. ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Swipe",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(text: " a machine left/right, "),
                            TextSpan(
                              text: "scan a QR code",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(text: ", or "),
                            TextSpan(
                              text: "tap your phone",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text:
                                  " on the NFC tag to claim a machine & mark it as in use by you.",
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
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
