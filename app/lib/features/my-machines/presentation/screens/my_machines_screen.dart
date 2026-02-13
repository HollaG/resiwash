import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/completed.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/in_use_by_you.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/issues_reported.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/subscriptions.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/usage_history.dart';

class MyMachinesScreen extends StatefulWidget {
  const MyMachinesScreen({super.key});

  @override
  State<MyMachinesScreen> createState() => _MyMachinesScreenState();
}

class _MyMachinesScreenState extends State<MyMachinesScreen> {
  bool hasCompletedMachines = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClaimCubit, ClaimState>(
      listener: (context, state) {
        // check if there are completed machines
        // if there are, show the demo explanation
        final completedMachines = (state.claimedMachines ?? [])
            .where(
              (machine) => machine.currentStatus == MachineStatus.available,
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
              actions: [],
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
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      AnimatedSize(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        alignment: Alignment.topCenter,
                        child: hasCompletedMachines
                            ? Container(
                                // height: 12,
                                decoration: BoxDecoration(
                                  // borderRadius: BorderRadius.only(
                                  //   bottomLeft: Radius.circular(
                                  //     24,
                                  //   ), // 24 = padding, 12 = inner radius
                                  //   bottomRight: Radius.circular(24),
                                  // ),
                                  gradient: LinearGradient(
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
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: CompletedSection(),
                                ),
                              )
                            : SizedBox(height: 0),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          spacing: 20,

                          children: [
                            // SizedBox(height: 0),

                            // section 0:
                            // "completed"
                            // AnimatedSize(
                            //   duration: Duration(milliseconds: 300),
                            //   curve: Curves.fastOutSlowIn,
                            //   alignment: Alignment.topCenter,
                            //   child: CompletedSection(),
                            // ),
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

                            // section 2:
                            // "Subscribed Machines"
                            // list of subscribed machines
                            SubscriptionsSection(),
                            // section 3:
                            // Issues reported
                            // list of issues
                            IssuesReportedSection(),
                            // section 4:
                            // Usage history
                            // list of usage history
                            UsageHistorySection(),
                          ],
                        ),
                      ),
                    ],
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
