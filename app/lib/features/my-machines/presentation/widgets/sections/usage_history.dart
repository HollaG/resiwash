import 'package:flutter/material.dart';

class UsageHistorySection extends StatelessWidget {
  const UsageHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Usage History",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  RichText(
                    text: TextSpan(
                      text: "Coming soon",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // OutlinedButton.icon(
            //   onPressed: () {},
            //   label: Text("Edit"),
            //   icon: Icon(Icons.edit),
            // ),
            // IconButton(onPressed: () {}, icon: Icon(Icons.add)),
          ],
        ),
        // List of machines in use by the user
      ],
    );
  }
}
