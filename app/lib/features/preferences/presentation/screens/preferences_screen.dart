import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/preferences/presentation/widgets/sections/machine_default_cycle.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String buildVersion = "Loading...";

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((packageInfo) {
      setState(() {
        buildVersion = packageInfo.version;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClaimCubit, ClaimState>(
      listener: (context, state) {},
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBarComponent(actions: [], title: "App settings"),
            body:
                // RefreshIndicator(
                //   child:
                SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,

                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          spacing: 20,
                          children: [
                            // default cycle time (washer)
                            MachineDefaultCycle(
                              machineType: MachineType.washer,
                            ),

                            MachineDefaultCycle(machineType: MachineType.dryer),

                            // default cycle time (dryer)
                            Divider(),
                            Text(
                              "Current build version: ${buildVersion}",
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            //   // onRefresh: () async {
            //   //   // Refresh both subscription and claim cubits
            //   //   await Future.wait([
            //   //     // context.read<SubscriptionCubit>().refreshSubscribedMachines(),
            //   //     // context.read<ClaimCubit>().refreshClaimedMachines(),
            //   //   ]);
            //   // },
            // ),
          );
        },
      ),
    );
  }
}
