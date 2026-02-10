import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/utils/subscription_utils.dart';
import 'package:resiwash/core/widgets/status_row_summary.dart';
import 'package:resiwash/features/area/domain/usecases/get_area_use_case.dart';
import 'package:resiwash/features/area/presentation/cubit/area_detail_cubit.dart';
import 'package:resiwash/features/area/presentation/cubit/area_detail_state.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_list_cubit.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_list_state.dart';
import 'package:resiwash/core/shared/mixins/error_handler_mixin.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_list_app_bar.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row_slidable_explanation.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/machine_group_subscription.dart';
import 'package:resiwash/features/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_cubit.dart';

enum ChipSelectionType { machine, room, status }

class MachineListScreen extends StatefulWidget {
  final String? query;
  final List<String>? areaIds;
  final List<String>? roomIds;
  final List<String>? machineIds;
  final List<String>? types;

  final String? title;
  final String? count;

  const MachineListScreen({
    super.key,
    this.query,
    this.areaIds,
    this.roomIds,
    this.machineIds,
    this.title,
    this.count,
    this.types,
  });

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen>
    with ErrorHandlerMixin {
  @override
  Widget build(BuildContext context) {
    // Name logic:
    // if exactly one roomId, display room name
    // if exactly one areaId, display area name
    // else, display "Machines"

    // possible extensions: Washer / Dryer type

    return MultiBlocProvider(
      providers: [
        BlocProvider<MachineListCubit>(
          create: (context) =>
              MachineListCubit(listMachinesUseCase: sl<ListMachinesUseCase>())
                ..load(
                  roomIds: widget.roomIds,
                  areaIds: widget.areaIds,
                  types: widget.types,
                  machineIds: widget.machineIds,
                  extra: true,
                ),
        ),
      ],
      child: Scaffold(
        appBar: MachineListAppBar(
          roomIds: widget.roomIds ?? [],
          areaIds: widget.areaIds ?? [],
          title: widget.title,
          count: widget.count,
        ),
        body: BlocConsumer<MachineListCubit, MachineListState>(
          listener: (context, state) {
            // Listen for error states and show toast
            if (state is MachineListError) {
              showErrorMessage(state.message, onRetry: () {});
            }
          },
          builder: (context, state) {
            if (state is MachineListLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is MachineListLoaded) {
              List<MachineEntity> machines = state.machines;
              List<MachineEntity> washers = machines
                  .where((machine) => machine.type == MachineType.washer)
                  .toList();
              List<MachineEntity> dryers = machines
                  .where((machine) => machine.type == MachineType.dryer)
                  .toList();

              return Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: RefreshIndicator(
                  onRefresh: () {
                    final completer = Completer<void>();
                    context
                        .read<MachineListCubit>()
                        .load(
                          roomIds: widget.roomIds,
                          areaIds: widget.areaIds,
                          types: widget.types,
                          machineIds: widget.machineIds,
                          extra: true,
                        )
                        .then((_) => completer.complete());
                    return completer.future;
                  },
                  child: ListView(
                    children: [
                      SizedBox(height: 16),
                      if (washers.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: StatusRowSummary(
                                label: "Washers",
                                machines: washers,
                              ),
                            ),
                            if (widget.roomIds != null &&
                                widget.roomIds!.isNotEmpty)
                              MachineGroupSubscription(
                                subscriptionKeys: widget.roomIds!
                                    .map(
                                      (e) =>
                                          SubscriptionUtils.getTopicNameForGroup(
                                            e,
                                            MachineType.washer,
                                          ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ],
                      if (dryers.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: StatusRowSummary(
                                label: "Dryers",
                                machines: dryers,
                              ),
                            ),
                            if (widget.roomIds != null &&
                                widget.roomIds!.isNotEmpty)
                              MachineGroupSubscription(
                                subscriptionKeys: widget.roomIds!
                                    .map(
                                      (e) =>
                                          SubscriptionUtils.getTopicNameForGroup(
                                            e,
                                            MachineType.dryer,
                                          ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Divider(),
                      ),
                      ...state.machines.map((machine) {
                        return MachineRow(machine: machine);
                      }),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Divider(),
                      ),

                      MachineRowSlidableExplanation(
                        initialPeekState: PeekState.left,
                      ),
                      MachineRowSlidableExplanation(
                        initialPeekState: PeekState.right,
                      ),
                      MachineRowSlidableExplanation(),
                    ],
                  ),
                ),
              );
            }

            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
