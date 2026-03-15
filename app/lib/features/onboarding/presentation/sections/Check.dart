import 'package:flutter/material.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/OnboardingInfoCard.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/hero_layout_card.dart';
import 'package:resiwash/theme.dart';

class Check extends StatefulWidget {
  const Check({Key? key}) : super(key: key);

  @override
  State<Check> createState() => _CheckState();
}

class _CheckState extends State<Check> {
  final CarouselController controller = CarouselController(initialItem: 1);
  final HeroMediaInfo mediaInfo = const HeroMediaInfo(
    assetPath: 'assets/onboarding/add_rooms.mp4',
    title: '',
    subtitle: '',
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Check",
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              // fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          "Add rooms to keep track of availability and statuses at a glance.",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 2,
            children: [
              Row(
                children: [
                  MachineStatusIndicator(status: MachineStatus.available),
                  SizedBox(width: 8),
                  Text(
                    "Available",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.success.colorContainer,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  MachineStatusIndicator(status: MachineStatus.inUse),
                  SizedBox(width: 8),
                  Text(
                    "In Use",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.inUse.colorContainer,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  MachineStatusIndicator(status: MachineStatus.finishing),
                  SizedBox(width: 8),
                  Text(
                    "Finishing (expected to finish in ~10 mins)",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.inUse.colorContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AspectRatio(
                aspectRatio: 1080 / 2340,
                child: HeroLayoutCard(mediaInfo: mediaInfo),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
