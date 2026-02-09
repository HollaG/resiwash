import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';

import 'package:resiwash/core/widgets/detail_row.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_cubit.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_state.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_timeline.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart'
    as claim_state;
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_state.dart'
    as sub_state;

enum InitialPageAction { none, subscribe, unsubscribe, claim, unclaim }

class MachineDetailScreen extends StatefulWidget {
  final String machineId;
  final InitialPageAction initialAction;

  const MachineDetailScreen({
    super.key,
    required this.machineId,
    this.initialAction = InitialPageAction.none,
  });

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  int isSubscribed = 0; // 0 = false, 1 = true, 2 = loading
  bool _hasHandledInitialAction = false;

  @override
  void initState() {
    super.initState();
  }

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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              MachineDetailCubit(getMachineUseCase: sl<GetMachineUseCase>())
                ..load(machineId: widget.machineId, extra: true),
        ),
        BlocProvider(
          create: (_) => sl<SubscriptionCubit>()..loadSubscribedMachines(),
        ),
        // ClaimCubit is already provided at app level in main.dart, no need to provide again
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MachineDetailCubit, MachineDetailState>(
            listener: (context, state) async {
              if (state is MachineDetailLoaded &&
                  !_hasHandledInitialAction &&
                  widget.initialAction == InitialPageAction.claim) {
                _hasHandledInitialAction = true;
                final machine = state.machine;
                int? cycleTime = await _dialogBuilder(context);
                if (cycleTime != null && mounted && context.mounted) {
                  context.read<ClaimCubit>().claimMachine(
                    machine,
                    cycleTime: cycleTime,
                  );
                }
              }
            },
          ),
          BlocListener<ClaimCubit, claim_state.ClaimState>(
            listener: (context, state) {
              // Reload the machine detail if the operating machine matches this screen's machine
              if (state is claim_state.Claimed) {
                final operatingMachineId = state.operatingMachine.machineId;
                if (operatingMachineId == widget.machineId) {
                  context.read<MachineDetailCubit>().load(
                    machineId: widget.machineId,
                    extra: true,
                  );
                }
              } else if (state is claim_state.Unclaimed) {
                final operatingMachineId = state.operatingMachine.machineId;
                if (operatingMachineId == widget.machineId) {
                  context.read<MachineDetailCubit>().load(
                    machineId: widget.machineId,
                    extra: true,
                  );
                }
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBarComponent(actions: [], title: 'Machine Detail'),
          body: BlocConsumer<MachineDetailCubit, MachineDetailState>(
            listener: (context, state) {
              // if (state is MachineDetailError) {
              //   showErrorMessage(state.message, onRetry: () {});
              // }
            },
            builder: (context, state) {
              if (state is MachineDetailLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (state is MachineDetailLoaded) {
                final machine = state.machine;
                return RefreshIndicator(
                  onRefresh: () {
                    // do a 1s test delay first
                    late Completer<void> completer;
                    completer = Completer<void>();
                    context
                        .read<MachineDetailCubit>()
                        .load(machineId: widget.machineId, extra: true)
                        .then((_) => completer.complete());
                    return completer.future;
                  },
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                      width: double.infinity,
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TODO: some image here
                          Row(
                            spacing: 8,
                            children: [
                              BlocConsumer<ClaimCubit, claim_state.ClaimState>(
                                listener: (context, state) {
                                  print("debug state emitted: $state");
                                },
                                builder: (context, state) {
                                  if (state is claim_state.ClaimLoading) {
                                    return Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {},
                                        child: SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (state is claim_state.ClaimLoaded) {
                                    bool isClaimed = context
                                        .read<ClaimCubit>()
                                        .isMachineClaimed(widget.machineId);
                                    if (isClaimed) {
                                      return Expanded(
                                        child: FilledButton(
                                          onPressed: () {
                                            context
                                                .read<ClaimCubit>()
                                                .unclaimMachine(machine);
                                          },
                                          child: Text("Unclaim"),
                                        ),
                                      );
                                    } else {
                                      return Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            final cycleTime =
                                                await _dialogBuilder(context);
                                            print(
                                              'debug cycletime: $cycleTime mounted $mounted context.mounted ${context.mounted}',
                                            );
                                            if (cycleTime != null &&
                                                mounted &&
                                                context.mounted) {
                                              print(
                                                'debug eh - about to claim',
                                              );
                                              if (!context.mounted) return;
                                              context
                                                  .read<ClaimCubit>()
                                                  .claimMachine(
                                                    machine,
                                                    cycleTime: cycleTime,
                                                  );
                                            }
                                          },
                                          child: Text("Claim"),
                                        ),
                                      );
                                    }
                                  }

                                  return Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {},
                                      child: Text("Loading..."),
                                    ),
                                  );
                                },
                              ),
                              BlocConsumer<
                                SubscriptionCubit,
                                sub_state.SubscriptionState
                              >(
                                listener: (context, state) {
                                  // handle subscription state changes if needed
                                },
                                builder: (context, state) {
                                  if (state is sub_state.SubscriptionLoading) {
                                    return Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {},
                                        child: SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (state is sub_state.SubscriptionLoaded) {
                                    bool isSubscribed = context
                                        .read<SubscriptionCubit>()
                                        .isSubscribedToMachine(
                                          widget.machineId,
                                        );
                                    if (isSubscribed) {
                                      return Expanded(
                                        child: FilledButton(
                                          onPressed: () {
                                            context
                                                .read<SubscriptionCubit>()
                                                .unsubscribeFromMachine(
                                                  machine,
                                                );
                                          },
                                          child: Text("Unsubscribe"),
                                        ),
                                      );
                                    } else {
                                      return Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            if (mounted && context.mounted) {
                                              context
                                                  .read<SubscriptionCubit>()
                                                  .subscribeToMachine(machine);
                                            }
                                          },
                                          child: Text("Subscribe"),
                                        ),
                                      );
                                    }
                                  }

                                  return Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {},
                                      child: Text("Loading..."),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          // rounded pill box that displays machine status
                          Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        MachineStatusIndicator.getBackgroundColor(
                                          context,
                                          machine.currentStatus,
                                        ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,

                                    children: [
                                      MachineStatusIndicator(
                                        status: machine.currentStatus,
                                        size: BoxSize.large,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        MachineDisplayUtils.getStatusLabel(
                                          machine,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color:
                                                  MachineStatusIndicator.getOnContainerColor(
                                                    context,
                                                    machine.currentStatus,
                                                  ),
                                            ),
                                      ),
                                      // box to take up the rest of the space
                                      // Spacer(),
                                    ],
                                  ),
                                ),
                              ),
                              // SubscriptionIndicator(
                              //   machineId: machine.machineId,
                              // ),
                            ],
                          ),

                          Row(
                            spacing: 8,
                            children: [
                              Text(
                                machine.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge,
                              ),
                              machine.type == MachineType.washer
                                  ? AssetIcons.washerIcon(context)
                                  : AssetIcons.dryerIcon(context),
                            ],
                          ),
                          DetailRow(
                            label: "Type",
                            content: MachineDisplayUtils.getType(machine),
                          ),
                          DetailRow(
                            label: "Label",
                            content: MachineDisplayUtils.getLabel(machine),
                          ),
                          DetailRow(
                            label: "Location",
                            content: MachineDisplayUtils.getLocationLabel(
                              machine,
                            ),
                          ),
                          DetailRow(
                            label: "Last updated",
                            content: MachineDisplayUtils.getLastUpdatedLabel(
                              machine,
                            ),
                          ),

                          Divider(),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Usage history",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                        ),
                                  ),
                                ],
                              ),
                              MachineTimeline(machine: machine),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Active issues (0)",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                        ),
                                  ),
                                ],
                              ),
                              Column(children: [Text("Feature coming soon!")]),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Issue history",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                        ),
                                  ),
                                ],
                              ),
                              Column(children: [Text("Feature coming soon!")]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text("Loading...")],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
