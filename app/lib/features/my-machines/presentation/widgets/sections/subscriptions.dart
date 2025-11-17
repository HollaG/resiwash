import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_state.dart'
    as sub_state;

import 'package:implicitly_animated_list/implicitly_animated_list.dart';

class SubscriptionsSection extends StatelessWidget {
  const SubscriptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, sub_state.SubscriptionState>(
      listener: (context, state) {},
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
            if (state is sub_state.SubscriptionLoading)
              Center(child: CircularProgressIndicator()),

            if (state is sub_state.SubscriptionLoaded &&
                state.subscribedMachines != null &&
                state.subscribedMachines!.isNotEmpty)
              ImplicitlyAnimatedList(
                physics: NeverScrollableScrollPhysics(),
                // key: _listKey,
                itemData: state.subscribedMachines!,
                itemBuilder: (_, machine) {
                  return MachineRow(
                    key: ValueKey(machine.machineId),
                    machine: machine,
                  );
                },
                shrinkWrap: true,
              ),

            // if (state is MyMachinesLoaded)
            //   Column(
            //     children:
            //         state.subscribedMachines != null &&
            //             state.subscribedMachines!.isNotEmpty
            //         ? state.subscribedMachines
            //               .map((machine) => MachineRow(machine: machine))
            //               .toList()
            //         : [
            //             Text(
            //               "You are not subscribed to any machines.",
            //               style: Theme.of(context).textTheme.bodyMedium,
            //             ),
            //           ],
            //   ),
          ],
        );
      },
    );
  }
}
