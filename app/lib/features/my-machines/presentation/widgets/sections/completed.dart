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
import 'package:resiwash/theme.dart';

class CompletedSection extends StatefulWidget {
  const CompletedSection({super.key});

  @override
  State<CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<CompletedSection> {
  bool isEditingClaimed = false;
  bool canEditClaimed = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClaimCubit, claim_state.ClaimState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is claim_state.ClaimLoaded) {
          // filter out to only have avaailble machines
          final completedMachines = state.claimedMachines!
              .where(
                (machine) => machine.currentStatus == MachineStatus.available,
              )
              .toList();

          final completedMetadata = state.claimedMachineMetadata
              .where(
                (meta) => completedMachines.any(
                  (machine) => machine.machineId == meta.machineId,
                ),
              )
              .toList();

          if (completedMachines.isEmpty) return SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 12,

            children: [
              // Row(
              //   children: [
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             "Completed",
              //             style: Theme.of(context).textTheme.headlineSmall,
              //           ),
              //           RichText(
              //             text: TextSpan(
              //               text:
              //                   "Swipe right on a machine to release it. You'll no longer be notified on changes after releasing.",
              //               style: Theme.of(context).textTheme.bodySmall,
              //             ),
              //           ),
              //           // Text(
              //           //   "Swipe to edit",
              //           //   style: Theme.of(context).textTheme.bodySmall,
              //           // ),
              //         ],
              //       ),
              //     ),
              //   ],
              // ),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.appColors.success.onColor,
                    ),
                    children: [
                      TextSpan(text: "You have "),
                      TextSpan(
                        text: "${completedMachines.length}",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: context.appColors.success.onColor,
                            ),
                      ),
                      TextSpan(text: " finished machines.\n"),

                      TextSpan(
                        text:
                            "\nPlease do collect your laundry as soon as possible! Remember to release this machine once you've collected.",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),

              // claimed machines
              if (completedMetadata.isNotEmpty && completedMetadata.isNotEmpty)
                Column(
                  spacing: 8,
                  children: completedMetadata
                      .map(
                        (claimedMeta) => Tracker(
                          key: Key(claimedMeta.machineId),
                          showControls: true,
                          claimedMetadata: claimedMeta,
                          machine: (completedMachines).firstWhere(
                            (machine) =>
                                machine.machineId == claimedMeta.machineId,
                          ),
                        ),
                      )
                      .toList(),
                ),

              // Padding(
              //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),

              //   child: Column(
              //     spacing: 8,
              //     children: [
              //       Text(
              //         textAlign: TextAlign.center,
              //         "You have not marked any machines as in use. ",
              //         style: Theme.of(context).textTheme.bodyMedium,
              //       ),
              //       Text(
              //         textAlign: TextAlign.center,
              //         "Swipe right on a machine, or scan a QR code to mark a machine as in use by you.",
              //         style: Theme.of(context).textTheme.bodyMedium,
              //       ),
              //       MachineRowSlidableExplanation(
              //         initialPeekState: PeekState.left,
              //       ),
              //     ],
              //   ),
              // ),
            ],
          );

          // List of machines in use by the user
        }

        if (state is claim_state.ClaimLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return SizedBox.shrink();
      },
    );
  }
}
