import 'package:flutter/material.dart';
import 'package:resiwash/demo/machine_row_slidable_explanation.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/hero_layout_card.dart';
import 'package:resiwash/theme.dart';

class Claim extends StatefulWidget {
  const Claim({Key? key}) : super(key: key);

  @override
  State<Claim> createState() => _ClaimState();
}

class _ClaimState extends State<Claim> {
  final HeroMediaInfo mediaInfo = const HeroMediaInfo(
    assetPath: 'assets/onboarding/add_rooms.mp4',
    title: 'Add rooms',
    subtitle: '',
  );

  @override
  void dispose() {
    super.dispose();
  }

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
              "Claim",
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                // fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff515b92).withAlpha(200),
                  blurRadius: 24,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: Colors.white.withAlpha(40),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              clipBehavior: Clip.hardEdge,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.white),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Set a timer on your phone by claiming a machine. Faster than manual setting!",
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: [
              Icon(Icons.mark_unread_chat_alt, color: Colors.white),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Get reminded if you left something behind",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.diversity_1, color: Colors.white),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Let others see your cycle progress and plan better!",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),

          Text(
            "Remember to release the machine once you've collected your clothes! Simply repeat the actions below to release.",
          ),
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  // indicator: RectangularIndicator(color: Colors.white),
                  tabs: [
                    Tab(icon: Icon(Icons.contactless)),
                    Tab(icon: Icon(Icons.qr_code_scanner)),
                    Tab(icon: Icon(Icons.phone_android)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0.0,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    height: 800,
                    child: TabBarView(
                      children: [ScanNfc(), ScanQr(), PhoneApp()],
                    ),
                  ),
                ),
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
          "Claim/Release with Phone",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          "Swipe a machine to claim or release it. Try it on the test machine below!",
        ),
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
          "Claim/Release with QR Code",
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
          "Claim/Release with NFC",
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
