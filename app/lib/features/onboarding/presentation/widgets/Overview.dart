import 'package:flutter/material.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/OnboardingInfoCard.dart';
import 'package:resiwash/theme.dart';

class Overview extends StatelessWidget {
  const Overview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              "Knowledge base",
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "What do you want to know?",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),

        Column(
          spacing: 16,
          children: [
            OnboardingInfoCard(
              title: "Check",
              titleAccompany: " for availability",
              body: "Learn how to check and interpret machine statuses",
              onTap: () {
                debugPrint('Card tapped.');
              },
              actionText: "View",
            ),
            OnboardingInfoCard(
              title: "Claim",
              titleAccompany: " your machine",
              body:
                  "See how ResiWash supports you with automatic timers & reminders.",
              onTap: () {
                debugPrint('Card tapped.');
              },
              actionText: "View",
            ),
            OnboardingInfoCard(
              title: "Contact",
              titleAccompany: " previous users",
              body:
                  "Something left in the machine? Get in touch with the last user to sort it out.",
              onTap: () {
                debugPrint('Card tapped.');
              },
              actionText: "View",
            ),
          ],
        ),
      ],
    );
  }
}
