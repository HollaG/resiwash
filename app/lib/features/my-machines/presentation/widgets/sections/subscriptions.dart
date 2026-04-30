import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/extensions/string_extensions.dart';
import 'package:resiwash/core/widgets/status_row_summary.dart';
import 'package:resiwash/demo/machine_group_subscription_demo.dart';
import 'package:resiwash/demo/status_row_summary_demo.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_row.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_state.dart'
    as sub_state;

import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/machine_group_subscription.dart';

class SubscriptionsSection extends StatelessWidget {
  const SubscriptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, sub_state.SubscriptionState>(
      listener: (context, state) {
        if (state is sub_state.SubscriptionLoaded) {
          print(
            "debug loaded state: ${state.subscribedGroups} ${state.subscribedGroupKeys}",
          );
        }
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
                // OutlinedButton.icon(
                //   onPressed: () {},
                //   label: Text("Edit"),
                //   icon: Icon(Icons.edit),
                // ),
                // IconButton(onPressed: () {}, icon: Icon(Icons.add)),
              ],
            ),
            // List of machines in use by the user
            if (state is sub_state.SubscriptionLoading)
              Center(child: CircularProgressIndicator()),

            if (state is sub_state.SubscriptionLoaded)
              if (state.subscribedGroups == null ||
                  state.subscribedGroups!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),

                  child: Column(
                    spacing: 8,
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        "You have not subscribed to any machines. ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        textAlign: TextAlign.center,
                        "Tap the switch widget to subscribe.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: StatusRowSummaryDemo(label: "Example"),
                          ),
                          MachineGroupSubscriptionDemo(),
                        ],
                      ),
                    ],
                  ),
                )
              else
                ImplicitlyAnimatedList(
                  physics: NeverScrollableScrollPhysics(),
                  // key: _listKey,
                  padding: EdgeInsets.fromLTRB(0, 16, 0, 0),

                  itemData: state.subscribedGroups?.keys.toList() ?? [],
                  itemEquality: (a, b) => a == b,
                  itemBuilder: (_, subscribedGroupKey) {
                    final machinesInGroup =
                        state.subscribedGroups?[subscribedGroupKey] ?? [];

                    if (machinesInGroup.isEmpty) {
                      return SizedBox.shrink();
                    }

                    // Assertion: all machines in a group have the same type
                    // NOTE: maynot be true in future if we allow mixed-type groups
                    final machineType = machinesInGroup
                        .first
                        .type; // OR subscribedGroupKey.split("_")[2] --> enum

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      key: ValueKey(subscribedGroupKey),
                      children: [
                        Row(
                          children: [
                            Text(
                              machinesInGroup.first.room?.shortName ??
                                  machinesInGroup.first.room?.name ??
                                  "Unknown",
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              " @ ${machinesInGroup.first.room?.area?.name ?? "Unknown"}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: StatusRowSummary(
                                label: "${machineType.name.capitalize()}s",
                                machines: machinesInGroup,
                              ),
                            ),
                            MachineGroupSubscription(
                              subscriptionKeys: [subscribedGroupKey],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                      ],
                    );
                  },
                  shrinkWrap: true,
                ),

            // if (state is sub_state.SubscriptionLoaded &&
            //     state.subscribedMachines != null &&
            //     state.subscribedMachines!.isNotEmpty)
            //   ImplicitlyAnimatedList(
            //     physics: NeverScrollableScrollPhysics(),
            //     // key: _listKey,
            //     itemData: state.subscribedMachines!,
            //     itemBuilder: (_, machine) {
            //       return MachineRow(
            //         key: ValueKey(machine.machineId),
            //         machine: machine,
            //       );
            //     },
            //     shrinkWrap: true,
            //   ),

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
