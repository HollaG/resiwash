import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<ClaimCubit, ClaimState>(
      listener: (context, state) {},
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBarComponent(
              actions: [],
              title: "Notification preferences",
            ),
            body: RefreshIndicator(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,

                    child: Column(children: [
                        
                      ],
                    ),
                  ),
                ),
              ),
              onRefresh: () async {
                // Refresh both subscription and claim cubits
                await Future.wait([
                  // context.read<SubscriptionCubit>().refreshSubscribedMachines(),
                  // context.read<ClaimCubit>().refreshClaimedMachines(),
                ]);
              },
            ),
          );
        },
      ),
    );
  }
}
