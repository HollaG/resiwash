import 'package:flutter/material.dart';

class MachineUsageHistory extends StatelessWidget {
  const MachineUsageHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage History',
            // style: Theme.of(context).,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Replace with actual usage count
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Usage #${index + 1}'),
                  subtitle: Text(
                    'Date & Time',
                  ), // Replace with actual date & time
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
