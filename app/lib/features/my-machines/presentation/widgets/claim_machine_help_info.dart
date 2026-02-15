import 'package:flutter/material.dart';

class ClaimMachineHelpInfo {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What is this?'),
        content: Column(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan the QR code pasted on the machines to mark them as in use by you.',
            ),
            const Text(
              "A timer will be set automatically on your phone and you will be notified once your machine is done.",
            ),
            Divider(),
            const Text(
              "Alternatively, you can tap your phone on the QR code (NFC enabled).",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
