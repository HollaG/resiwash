import 'package:flutter/material.dart';

/// A reusable widget for displaying label-value pairs in detail screens
class DetailRow extends StatelessWidget {
  final String label;
  final String content;
  final TextStyle? labelStyle;
  final TextStyle? contentStyle;

  const DetailRow({
    super.key,
    required this.label,
    required this.content,
    this.labelStyle,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style:
              labelStyle ??
              Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
        const Spacer(flex: 1),
        Text(
          content,
          style: contentStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
