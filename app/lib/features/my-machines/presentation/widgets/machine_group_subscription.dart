import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_state.dart';

class MachineGroupSubscription extends StatefulWidget {
  final List<String> subscriptionKeys;

  const MachineGroupSubscription({super.key, required this.subscriptionKeys});

  @override
  State<MachineGroupSubscription> createState() =>
      _MachineGroupSubscriptionState();
}

class _MachineGroupSubscriptionState extends State<MachineGroupSubscription> {
  bool _isSubscribed = false;
  bool _isLoading = false;
  late WidgetStateProperty<Icon> thumbIconSubscribed;

  @override
  void initState() {
    super.initState();

    // read the initial subscription state
    _isSubscribed = context.read<SubscriptionCubit>().isSubscribedToGroups(
      widget.subscriptionKeys,
    );
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

  void onSwitchChanged(bool value) async {
    setState(() {
      _isLoading = true;
    });
    if (value) {
      await context.read<SubscriptionCubit>().subscribeToGroups(
        widget.subscriptionKeys,
      );
    } else {
      await context.read<SubscriptionCubit>().unsubscribeFromGroups(
        widget.subscriptionKeys,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (context, state) {
        // Remember that Subscribing and Unsubscribing extend SubscriptionLoaded (antipattern, but eh)
        if (state is SubscriptionLoaded) {
          setState(() {
            _isSubscribed = context
                .read<SubscriptionCubit>()
                .isSubscribedToGroups(widget.subscriptionKeys);
          });
        }
      },
      builder: (context, state) {
        return Switch(
          value: _isSubscribed,
          thumbIcon: thumbIconSubscribed,
          onChanged: _isLoading ? null : onSwitchChanged,

          // inactiveThumbImage:
        );
      },
    );
  }
}
