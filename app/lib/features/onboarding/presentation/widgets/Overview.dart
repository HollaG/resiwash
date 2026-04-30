import 'package:flutter/material.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/OnboardingInfoCard.dart';
import 'package:resiwash/theme.dart';

class Overview extends StatelessWidget {
  const Overview({
    Key? key,
    required this.onCheckTap,
    required this.onClaimTap,
    required this.onContactTap,
    required this.onDismiss,
  }) : super(key: key);

  final VoidCallback onCheckTap;
  final VoidCallback onClaimTap;
  final VoidCallback onContactTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),

          Column(
            spacing: 16,
            children: [
              OnboardingInfoCard(
                id: "check",
                title: "Check",
                titleAccompany: " for availability",
                body: Text(
                  "Learn how to check and interpret machine statuses",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                onTap: onCheckTap,
                actionText: "View",
              ),
              OnboardingInfoCard(
                id: "claim",
                title: "Claim",
                titleAccompany: " your machine",
                body: Text(
                  "See how ResiWash supports you with automatic timers & reminders.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                onTap: onClaimTap,
                actionText: "View",
              ),
              OnboardingInfoCard(
                id: "contact",
                title: "Contact",
                titleAccompany: " previous users",
                body: Text(
                  "Something left in the machine? Get in touch with the last user to sort it out.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                onTap: onContactTap,
                actionText: "Feature coming soon!",
              ),
            ],
          ),

          Center(
            child: FilledButton(onPressed: onDismiss, child: Text("I got it!")),
          ),
        ],
      ),
    );
  }
}
