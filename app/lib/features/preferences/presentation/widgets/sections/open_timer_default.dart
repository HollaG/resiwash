import 'package:flutter/material.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenTimerDefaultSwitch extends StatefulWidget {
  final Function(bool)? onChanged;

  const OpenTimerDefaultSwitch({Key? key, this.onChanged}) : super(key: key);

  @override
  State<OpenTimerDefaultSwitch> createState() => _OpenTimerDefaultSwitchState();
}

class _OpenTimerDefaultSwitchState extends State<OpenTimerDefaultSwitch> {
  bool canOpenTimer = false;

  @override
  void initState() {
    super.initState();

    bool _canOpenTimer = sl<SharedPreferencesService>()
        .shouldOpenTimerAfterClaiming();

    print("debug loaded opentimer preference: $_canOpenTimer");
    setState(() {
      canOpenTimer = _canOpenTimer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: canOpenTimer,
      onChanged: (value) {
        setState(() {
          canOpenTimer = value;
        });

        if (!value) {
          sl<SharedPreferencesService>().setOpenTimerAfterClaiming(false);
          print("debug set opentimer to false");
        } else {
          sl<SharedPreferencesService>().setOpenTimerAfterClaiming(true);
          print("debug set opentimer to true");
        }

        widget.onChanged?.call(canOpenTimer);
      },

      title: Text(
        "Auto-open timer",
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      // subtitle: Text("Bypass the cycle time selection screen"),
    );
  }
}
