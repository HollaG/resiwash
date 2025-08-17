import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resiwash/core/shared/machine/data/models/machine_model.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/common/views/homeMainCard.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  const HomeHeader({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(36.0, 48, 36, 48),
        color: Theme.of(context).colorScheme.primary,

        child: SafeArea(
          child: Column(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    "Welcome back,",
                    style:
                        GoogleFonts.poppinsTextTheme(
                          Theme.of(context).textTheme,
                        ).headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                  Text(
                    "Marcus!",
                    style:
                        GoogleFonts.poppinsTextTheme(
                          Theme.of(context).textTheme,
                        ).headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          // fontFamily: "Open Sans",
                        ),
                  ),
                ],
              ),

              BlocBuilder<OverviewCubit, OverviewState>(
                builder: (context, state) {
                  // Calculate counts based on actual data
                  int washerCount = 0;
                  int dryerCount = 0;
                  int totalWashers = 0;
                  int totalDryers = 0;

                  if (state is OverviewLoaded) {
                    // Count available/total washers and dryers
                    for (var machine in state.machines) {
                      if (machine.type == MachineType.washer) {
                        totalWashers++;
                        if (machine.currentStatus == MachineStatus.available) {
                          washerCount++;
                        }
                      } else if (machine.type == MachineType.dryer) {
                        totalDryers++;
                        if (machine.currentStatus == MachineStatus.available) {
                          dryerCount++;
                        }
                      }
                    }
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: HomeMainCard(
                          leading: AssetIcons.washerIcon(context),
                          title: "Washers",
                          count: state is OverviewLoaded
                              ? "$washerCount/$totalWashers"
                              : "0/0",
                          actionText: "View",
                          onAction: () {},
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: HomeMainCard(
                          leading: AssetIcons.dryerIcon(context),
                          title: "Dryers",
                          count: state is OverviewLoaded
                              ? "$dryerCount/$totalDryers"
                              : "0/0",
                          actionText: "View",
                          onAction: () {},
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
