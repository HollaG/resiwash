import 'package:flutter/material.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/domain/entities/event_entity.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/machine/presentation/widgets/machine_timeline.dart';
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

  final MachineEntity fakeMachine = MachineEntity(
    machineId: 'demo-machine-1',
    name: 'Washer A',
    label: 'A',
    type: MachineType.washer,
    roomId: 'demo-room-1',
    events: [
      EventEntity(
        eventId: 1,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        status: MachineStatus.available,
      ),
      EventEntity(
        eventId: 2,
        timestamp: DateTime.now().subtract(Duration(minutes: 10)),
        status: MachineStatus.finished,
      ),
      EventEntity(
        eventId: 3,
        timestamp: DateTime.now().subtract(Duration(minutes: 17)),
        status: MachineStatus.finishing,
      ),
      EventEntity(
        eventId: 4,
        timestamp: DateTime.now().subtract(Duration(minutes: 40)),
        status: MachineStatus.inUse,
      ),
      EventEntity(
        eventId: 5,
        timestamp: DateTime.now().subtract(Duration(minutes: 45)),
        status: MachineStatus.available,
      ),
    ],
    createdAt: DateTime(2026, 1, 1, 12, 0),
    updatedAt: DateTime(2026, 1, 1, 13, 15),
    lastUpdated: DateTime(2026, 1, 1, 13, 15),
    lastChangeTime: DateTime(2026, 1, 1, 13, 15),
    currentStatus: MachineStatus.available,
    previousStatus: MachineStatus.finished,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
                    MachineStatusIndicator(status: MachineStatus.finished),
                    SizedBox(width: 8),
                    Text(
                      "Finished (clothes waiting for pick up)",
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
          Text(
            "Note: Some users may forget to release the machine. In this case, use the app to see if it is an appropiate time to remove their clothes.",
          ),

          MachineTimeline(machine: fakeMachine),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 600),
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
      ),
    );
  }
}
