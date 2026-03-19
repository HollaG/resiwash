import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart'
    as claim_state;
import 'package:resiwash/features/my-machines/presentation/widgets/trackers/tracker_mini.dart';

class TrackerMiniContainer extends StatefulWidget {
  const TrackerMiniContainer({super.key});

  @override
  State<TrackerMiniContainer> createState() => _TrackerMiniContainerState();
}

class _TrackerMiniContainerState extends State<TrackerMiniContainer> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClaimCubit, claim_state.ClaimState>(
      builder: (context, state) {
        if (state is claim_state.ClaimLoaded) {
          final claimedMetaList = state.claimedMachineMetadata;
          final claimedMachineList = state.claimedMachines ?? [];

          final validMetaList = claimedMetaList
              .where(
                (meta) => claimedMachineList.any(
                  (machine) => machine.machineId == meta.machineId,
                ),
              )
              .toList();

          if (validMetaList.isEmpty) {
            return const SizedBox.shrink();
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: kToolbarHeight,
              maxWidth: 150,
            ),
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                final meta = validMetaList[index % validMetaList.length];

                return TrackerMini(
                  claimedMetadata: meta,
                  machine: claimedMachineList.firstWhere(
                    (machine) => machine.machineId == meta.machineId,
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
