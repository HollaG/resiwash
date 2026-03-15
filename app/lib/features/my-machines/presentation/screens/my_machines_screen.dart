import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/presentation/utils/machine_display_utils.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/completed.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/in_use_by_you.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/subscriptions.dart';

class MyMachinesScreen extends StatefulWidget {
  const MyMachinesScreen({super.key});

  @override
  State<MyMachinesScreen> createState() => _MyMachinesScreenState();
}

class _MyMachinesScreenState extends State<MyMachinesScreen> {
  bool hasCompletedMachines = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClaimCubit, ClaimState>(
      listener: (context, state) {
        // check if there are completed machines
        // if there are, show the demo explanation
        final completedMachines = (state.claimedMachines ?? [])
            .where(
              (machine) =>
                  MachineDisplayUtils.isAvailableLike(machine.currentStatus),
            )
            .toList();

        if (completedMachines.isNotEmpty) {
          setState(() {
            hasCompletedMachines = true;
          });
        } else {
          setState(() {
            hasCompletedMachines = false;
          });
        }

        print(
          "debug Completed machines: ${completedMachines.length}, hasCompletedMachines: $hasCompletedMachines",
        );
      },
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBarComponent(
              actions: [
                // IconButton(onPressed: () {}, icon: Icon(Icons.help_outline)),
              ],
              title: "My Machines",
              backgroundColor: hasCompletedMachines
                  ? MachineStatusIndicator.getBackgroundColor(
                      context,
                      MachineStatus.available,
                    )
                  : null,
            ),
            body: RefreshIndicator(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,

                    child: Column(
                      children: [
                        // for COMPLETED machines only. Should be minimally full height, but can expand if there are more completed machines. If no completed machines, should be 0 height.
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: hasCompletedMachines
                                ? LinearGradient(
                                    colors: [
                                      MachineStatusIndicator.getBackgroundColor(
                                        context,
                                        MachineStatus.available,
                                      ),
                                      MachineStatusIndicator.getIndicatorColor(
                                        context,
                                        MachineStatus.available,
                                      ),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : LinearGradient(
                                    colors: [
                                      Theme.of(context).scaffoldBackgroundColor,
                                      Theme.of(context).scaffoldBackgroundColor,
                                    ],
                                  ),
                          ),
                          child: AnimatedSize(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: hasCompletedMachines
                                ? ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight:
                                          MediaQuery.of(context).size.height -
                                          kToolbarHeight,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: CompletedSection(),
                                    ),
                                  )
                                : SizedBox(height: 0, width: double.infinity),
                          ),
                        ),

                        Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Column(
                              spacing: 20,

                              children: [
                                SizedBox(height: 0),

                                // section 1:
                                // "In use by you"
                                // list of in use by you
                                AnimatedSize(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.fastOutSlowIn,
                                  alignment: Alignment.topCenter,
                                  child: InUseByYouSection(),
                                ),

                                Divider(),

                                // section 2:
                                // "Subscribed Machines"
                                // list of subscribed machines
                                // SubscriptionsSection(),

                                // Divider(),
                                // section 3:
                                // Issues reported
                                // list of issues
                                // IssuesReportedSection(),
                                // section 4:
                                // Usage history
                                // list of usage history
                                // UsageHistorySection(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              onRefresh: () async {
                // Refresh both subscription and claim cubits
                await Future.wait([
                  context.read<SubscriptionCubit>().refreshSubscribedMachines(),
                  context.read<ClaimCubit>().refreshClaimedMachines(),
                ]);
              },
            ),
          );
        },
      ),
    );
  }
}
