// app bar component
import 'package:flutter/material.dart';

class AppBarComponent extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppBarComponent({
    super.key,
    required this.actions,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onPrimary,
        fontFamily: "Poppins",
      ),
      // titleTextStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
      //   fontWeight: FontWeight.bold,
      //   color: Theme.of(context).colorScheme.onPrimary,
      // ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
