import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_state.dart';

class SubscriptionsSection extends StatelessWidget {
  const SubscriptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyMachinesCubit, MyMachinesState>(
      listener: (context, state) {
        print("SubscriptionsSection state changed: $state");
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Subscriptions",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      RichText(
                        text: TextSpan(
                          text:
                              "Receive a notification whenever a machine's status changes",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  label: Text("Edit"),
                  icon: Icon(Icons.edit),
                ),
                // IconButton(onPressed: () {}, icon: Icon(Icons.add)),
              ],
            ),
            // List of machines in use by the user
            if (state is MyMachinesLoading)
              Center(child: CircularProgressIndicator()),

            if (state is MyMachinesLoaded)
              Column(
                children: state.machines != null && state.machines!.isNotEmpty
                    ? state.machines!
                          .map((machine) => MachineRow(machine: machine))
                          .toList()
                    : [
                        Text(
                          "You are not subscribed to any machines.",
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
