import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_state.dart';

class MachineGroupSubscription extends StatefulWidget {
  final List<String> subscriptionKeys;

  const MachineGroupSubscription({Key? key, required this.subscriptionKeys})
    : super(key: key);

  @override
  State<MachineGroupSubscription> createState() =>
      _MachineGroupSubscriptionState();
}

class _MachineGroupSubscriptionState extends State<MachineGroupSubscription> {
  bool _isSubscribed = false;
  late WidgetStateProperty<Icon> thumbIconSubscribed;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    thumbIconSubscribed =
        WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
          WidgetState.selected: Icon(
            Icons.notifications_active_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          WidgetState.any: Icon(Icons.notifications_off_rounded),
        });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (context, state) => {},
      builder: (context, state) {
        if (state is SubscriptionLoaded) {
          // _isSubscribed = widget.subscriptionKeys
          // .every((key) => state.subscriptions.contains(key));
        }
        return Switch(
          value: _isSubscribed,
          thumbIcon: thumbIconSubscribed,
          onChanged: (value) {
            setState(() {
              _isSubscribed = value;
            });
          },
        );
      },
    );
  }
}
