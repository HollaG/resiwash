import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/services/notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/subscription_utils.dart';
import 'package:resiwash/core/widgets/detail_row.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_cubit.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_state.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_timeline.dart';
import 'package:resiwash/features/machine/presentation/widgets/subscription_indicator.dart';

class MachineDetailScreen extends StatefulWidget {
  final String machineId;

  const MachineDetailScreen({super.key, required this.machineId});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  int isSubscribed = 0; // 0 = false, 1 = true, 2 = loading

  @override
  void initState() {
    super.initState();

    // initialize the subscription status
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final sharedPref = sl<SharedPreferencesService>();

    //   bool subscribed = sharedPref.isSubscribedToMachine(widget.machineId);

    //   setState(() {
    //     isSubscribed = subscribed ? 1 : 0;
    //   });
    // });
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
                            SubscriptionIndicator(machineId: machine.machineId),
                          ],
                        ),

                        Row(
                          spacing: 8,
                          children: [
                            Text(
                              machine.name,
                              style: Theme.of(context).textTheme.headlineLarge,
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
    );
  }
}
