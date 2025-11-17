import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/in_use_by_you.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/issues_reported.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/subscriptions.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/sections/usage_history.dart';

class MyMachinesScreen extends StatelessWidget {
  const MyMachinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          appBar: AppBarComponent(actions: [], title: "My Machines"),
          body: RefreshIndicator(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
    );
  }
}
