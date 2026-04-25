import 'package:flutter/material.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

class UseRealCycleTimesDefaultSwitch extends StatefulWidget {
  Function(bool)? onChanged;

  UseRealCycleTimesDefaultSwitch({super.key, this.onChanged});

  @override
  State<UseRealCycleTimesDefaultSwitch> createState() =>
      _UseRealCycleTimesDefaultSwitchState();
}

class _UseRealCycleTimesDefaultSwitchState
    extends State<UseRealCycleTimesDefaultSwitch> {
  bool useRealCycleTimes = true;

  @override
  void initState() {
    super.initState();

    bool _useRealCycleTimes = sl<SharedPreferencesService>()
        .shouldUseRealCycleTimes();

    print("debug loaded use real cycle times preference: $_useRealCycleTimes");
    setState(() {
      useRealCycleTimes = _useRealCycleTimes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: useRealCycleTimes,
      onChanged: (value) {
        setState(() {
          useRealCycleTimes = value;
        });

        if (!value) {
          sl<SharedPreferencesService>().setUseRealCycleTimes(false);
          print("debug set use real cycle times to false");
        } else {
          sl<SharedPreferencesService>().setUseRealCycleTimes(true);
          print("debug set use real cycle times to true");
        }
        widget.onChanged?.call(useRealCycleTimes);
      },

      title: Text(
        "Add 5 minutes",
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      // subtitle: Text("Bypass the cycle time selection screen"),
    );
  }
}
