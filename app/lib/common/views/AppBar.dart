// app bar component
import 'package:flutter/material.dart';
import 'package:resiwash/features/my-machines/presentation/widgets/trackers/tracker_mini_container.dart';

class AppBarComponent extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppBarComponent({
    super.key,
    required this.actions,
    required this.title,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [...?actions, TrackerMiniContainer()],
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor:
          foregroundColor ?? Theme.of(context).colorScheme.onPrimary,

      // titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      // titleTextStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
      //   fontWeight: FontWeight.bold,
      //   color: Theme.of(context).colorScheme.onPrimary,
      // ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
