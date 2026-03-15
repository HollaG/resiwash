import 'package:flutter/material.dart';
import 'package:resiwash/demo/machine_row_slidable_explanation.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/preferences/presentation/widgets/sections/machine_default_cycle.dart';
import 'package:resiwash/theme.dart';

class Claim2 extends StatefulWidget {
  const Claim2({Key? key}) : super(key: key);

  @override
  State<Claim2> createState() => _Claim2State();
}

class _Claim2State extends State<Claim2> {
  int selectedCycleTime = 30;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Claim (advanced)",
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                // fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Text(
            "1. Streamline claiming",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            "When claiming a machine, you will have to select your cycle time, so we can set an appropiate timer.",
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
              // boxShadow: [
              //   BoxShadow(
              //     color: Color(0xff515b92).withAlpha(200),
              //     blurRadius: 24,
              //     spreadRadius: 6,
              //   ),
              //   BoxShadow(
              //     color: Colors.white.withAlpha(40),
              //     blurRadius: 8,
              //     spreadRadius: 1,
              //   ),
              // ],
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 12.0,
              children: [
                Text(
                  'Please choose your cycle time for the machine you are using.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Center(
                  child: SegmentedButton(
                    multiSelectionEnabled: true,
                    emptySelectionAllowed: true,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return (Theme.of(context).colorScheme.primary);
                        }
                        return Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).colorScheme.onPrimary;
                        }
                        return Theme.of(context).colorScheme.onSurface;
                      }),
                    ),
                    segments: <ButtonSegment<int>>[
                      for (int cycleTime in [30, 45, 60])
                        ButtonSegment<int>(
                          value: cycleTime,
                          label: Text('${cycleTime}m'),
                        ),
                    ],
                    selected: <int>{},
                    onSelectionChanged: (Set<int> newSelection) {},
                  ),
                ),
              ],
            ),
          ),

          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                const TextSpan(
                  text:
                      'You can bypass this screen by setting a default cycle time (also accessible in ',
                ),
                TextSpan(
                  text: 'Settings',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '):'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              spacing: 8,
              children: [
                // default cycle time (washer)
                MachineDefaultCycle(machineType: MachineType.washer),

                MachineDefaultCycle(machineType: MachineType.dryer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneApp extends StatelessWidget {
  const PhoneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          "Claim with Phone",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text("Swipe a machine to claim it. Try it on the test machine below!"),
        Theme(
          data: MaterialTheme(Theme.of(context).textTheme).light(),
          child: MachineRowSlidableExplanation(),
        ),
      ],
    );
  }
}

class ScanQr extends StatelessWidget {
  const ScanQr({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          "Claim with QR Code",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          "Look for this QR code at the machine, and scan it (with any scanner!).",
        ),
        Center(
          child: SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/onboarding/claim_help.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScanNfc extends StatelessWidget {
  const ScanNfc({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          "Claim with NFC",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(
                text: 'Ensure NFC is enabled on your phone, then tap the ',
              ),
              TextSpan(
                text: 'red X',
                style: TextStyle(
                  color: context.appColors.reserved.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' in the center of the QR code to claim.'),
            ],
          ),
        ),
        // Text(
        //   "Remember to tap where the NFC reader on your phone is! For most Androids, it's near the back camera, while for iPhones, it's near the top edge.",
        // ),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/onboarding/nfc_info.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Center(
          child: SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/onboarding/claim_help_nfc.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Row(children: [
            
          ],
        ),
      ],
    );
  }
}
