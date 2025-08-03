// app bar component
import 'package:flutter/material.dart';

class AppBarComponent extends StatelessWidget implements PreferredSizeWidget {
  final String title = "Resiwash";
  final List<Widget>? actions;

  const AppBarComponent({Key? key, required this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      titleTextStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
        // fontWeight: FontWeight.bold,/
        color: Theme.of(context).colorScheme.onPrimary,
        // fontFamily: "Poppins"
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
