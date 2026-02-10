import 'package:flutter/material.dart';

/// A demonstration widget showing the MachineGroupSubscription UI structure
/// with simple on/off toggle - no business logic or cubit dependencies
class MachineGroupSubscriptionDemo extends StatefulWidget {
  const MachineGroupSubscriptionDemo({super.key});

  @override
  State<MachineGroupSubscriptionDemo> createState() =>
      _MachineGroupSubscriptionDemoState();
}

class _MachineGroupSubscriptionDemoState
    extends State<MachineGroupSubscriptionDemo> {
  bool _isSubscribed = false;
  late WidgetStateProperty<Icon> thumbIconSubscribed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    thumbIconSubscribed =
        WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
          WidgetState.selected: Icon(
            Icons.notifications_active_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          WidgetState.any: const Icon(Icons.notifications_off_rounded),
        });
  }

  void onSwitchChanged(bool value) {
    setState(() {
      _isSubscribed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _isSubscribed,
      thumbIcon: thumbIconSubscribed,
      onChanged: onSwitchChanged,
    );
  }
}
