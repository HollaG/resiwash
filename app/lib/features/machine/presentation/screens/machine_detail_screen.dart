import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_cubit.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_state.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';

class MachineDetailScreen extends StatefulWidget {
  final String machineId;

  const MachineDetailScreen({Key? key, required this.machineId})
    : super(key: key);

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              MachineDetailCubit(getMachineUseCase: sl<GetMachineUseCase>())
                ..load(machineId: widget.machineId),
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
              return Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          machine.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Location",
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        Spacer(flex: 1),
                        Text(
                          MachineDisplayUtils.getLocationLabel(machine),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Last change",
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        Spacer(flex: 1),
                        Text(
                          MachineDisplayUtils.getStatusLabel(machine),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "Usage history",
                              style: Theme.of(context).textTheme.headlineSmall
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
                              "Active issues (0)",
                              style: Theme.of(context).textTheme.headlineSmall
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
                              style: Theme.of(context).textTheme.headlineSmall
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
