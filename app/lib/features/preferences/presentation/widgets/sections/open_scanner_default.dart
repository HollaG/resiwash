import 'package:flutter/material.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenScannerDefaultSwitch extends StatefulWidget {
  final Function(bool)? onChanged;

  const OpenScannerDefaultSwitch({Key? key, this.onChanged}) : super(key: key);

  @override
  State<OpenScannerDefaultSwitch> createState() =>
      _OpenScannerDefaultSwitchState();
}

class _OpenScannerDefaultSwitchState extends State<OpenScannerDefaultSwitch> {
  bool canOpenScanner = false;

  @override
  void initState() {
    super.initState();

    bool _canOpenScanner = sl<SharedPreferencesService>()
        .shouldShowScannerOnStart();

    print("debug loaded openscanner preference: $_canOpenScanner");
    setState(() {
      canOpenScanner = _canOpenScanner;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: canOpenScanner,
      onChanged: (value) {
        setState(() {
          canOpenScanner = value;
        });

        // request for camera permission if not already granted and user is trying to enable the setting

        if (!value) {
          sl<SharedPreferencesService>().setShowScannerOnStart(false);
          print("debug set openscanner to false");
        } else {
          sl<SharedPreferencesService>().setShowScannerOnStart(true);
          print("debug set openscanner to true");
        }

        widget.onChanged?.call(canOpenScanner);
      },

      title: Text(
        "Auto-open scanner",
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      // subtitle: Text("Bypass the cycle time selection screen"),
    );
  }
}
