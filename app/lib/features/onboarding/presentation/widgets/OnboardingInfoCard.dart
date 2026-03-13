import 'package:flutter/material.dart';
import 'package:resiwash/theme.dart';

class OnboardingInfoCard extends StatelessWidget {
  const OnboardingInfoCard({
    super.key,
    required this.title,
    required this.titleAccompany,
    required this.body,
    required this.onTap,
    required this.actionText,
    required this.id,
  });

  final String title;
  final String titleAccompany;
  final Widget body;
  final String actionText;
  final VoidCallback onTap;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: id,
      child: Card(
        color: context.accent.colorContainer,
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          splashColor: Theme.of(context).colorScheme.primary.withAlpha(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  RichText(
                    text: TextSpan(
                      text: title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      children: [
                        TextSpan(
                          text: titleAccompany,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: context.accent.onColorContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                  body,
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: Text(
                      actionText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
