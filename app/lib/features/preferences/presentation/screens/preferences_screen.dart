import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/navigation/app_shell_page_controller.dart';
import 'package:resiwash/core/services/firebase_notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/snackbar_helper.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_state.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';
import 'package:resiwash/features/preferences/presentation/widgets/sections/machine_default_cycle.dart';
import 'package:resiwash/features/preferences/presentation/widgets/sections/open_scanner_default.dart';
import 'package:resiwash/features/preferences/presentation/widgets/sections/open_timer_default.dart';
import 'package:resiwash/features/preferences/presentation/widgets/sections/use_real_cycle_times.dart';
import 'package:resiwash/features/preferences/presentation/widgets/setting_tile.dart';
import 'package:resiwash/theme.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String buildVersion = "Loading...";

  bool _notificationPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((packageInfo) {
      setState(() {
        buildVersion = packageInfo.version;
      });
    });

    sl<FirebaseNotificationService>().hasNotificationPermission().then((
      granted,
    ) {
      setState(() {
        _notificationPermissionGranted = granted;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClaimCubit, ClaimState>(
      listener: (context, state) {},
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBarComponent(actions: [], title: "App settings"),
            body:
                // RefreshIndicator(
                //   child:
                SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SafeArea(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: double.infinity,
                        maxWidth: double.infinity,
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          spacing: 20,
                          children: [
                            if (!_notificationPermissionGranted)
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      context.appColors.reserved.colorContainer,

                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(16),

                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Please allow notifications to receive updates on your machine.",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onErrorContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        sl<FirebaseNotificationService>()
                                            .getPermission()
                                            .then((_) {
                                              // After requesting permission, check the status again
                                              sl<FirebaseNotificationService>()
                                                  .hasNotificationPermission()
                                                  .then((granted) {
                                                    setState(() {
                                                      _notificationPermissionGranted =
                                                          granted;
                                                    });
                                                    if (!granted) {
                                                      SnackbarHelper.showWarning(
                                                        message:
                                                            "Notification permission denied. You may miss important updates about your machine. Please allow in system settings.",
                                                      );
                                                    }
                                                  });
                                            });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                      child: const Text("Allow"),
                                    ),
                                  ],
                                ),
                              ),
                            // Row(
                            //   children: [
                            //     Expanded(
                            //       child: Column(
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         spacing: 2,

                            //         children: [
                            //           Text(
                            //             "Set claim defaults",
                            //             style: Theme.of(
                            //               context,
                            //             ).textTheme.headlineSmall,
                            //           ),
                            //           RichText(
                            //             text: TextSpan(
                            //               text:
                            //                   "When claiming a machine, you can bypass the cycle time selection screen by enabling the switch and choosing your typical cycle time. Note that you can still edit the cycle time after marking.",
                            //               style: Theme.of(
                            //                 context,
                            //               ).textTheme.bodySmall,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // Padding(
                            //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            //   child: Column(
                            //     spacing: 8,
                            //     children: [
                            //       // default cycle time (washer)
                            //       MachineDefaultCycle(
                            //         machineType: MachineType.washer,
                            //       ),

                            //       MachineDefaultCycle(
                            //         machineType: MachineType.dryer,
                            //       ),
                            //     ],
                            //   ),
                            // ),

                            // Divider(),
                            Builder(
                              builder: (context) {
                                int? washerDefaultCycleTime =
                                    sl<SharedPreferencesService>()
                                        .getPreferredCycleTime(
                                          MachineType.washer,
                                        );
                                int? dryerDefaultCycleTime =
                                    sl<SharedPreferencesService>()
                                        .getPreferredCycleTime(
                                          MachineType.dryer,
                                        );

                                TileState claimDefaultsState;
                                if (washerDefaultCycleTime != null &&
                                    dryerDefaultCycleTime != null) {
                                  claimDefaultsState = TileState.enabled;
                                } else if (washerDefaultCycleTime == null &&
                                    dryerDefaultCycleTime == null) {
                                  claimDefaultsState = TileState.disabled;
                                } else {
                                  claimDefaultsState = TileState.intermediate;
                                }

                                void onClaimDefaultsChanged() {
                                  setState(() {
                                    washerDefaultCycleTime =
                                        sl<SharedPreferencesService>()
                                            .getPreferredCycleTime(
                                              MachineType.washer,
                                            );
                                    dryerDefaultCycleTime =
                                        sl<SharedPreferencesService>()
                                            .getPreferredCycleTime(
                                              MachineType.dryer,
                                            );
                                  });
                                }

                                return SettingTile(
                                  initiallyExpanded: true,
                                  title: "Set claim defaults",
                                  subtitle:
                                      "When claiming a machine, you can bypass the cycle time selection screen by enabling the switch and choosing your typical cycle time. Note that you can still edit the cycle time after marking.",
                                  state: claimDefaultsState,
                                  children: [
                                    MachineDefaultCycle(
                                      machineType: MachineType.washer,
                                      onChanged: onClaimDefaultsChanged,
                                    ),

                                    MachineDefaultCycle(
                                      machineType: MachineType.dryer,
                                      onChanged: onClaimDefaultsChanged,
                                    ),
                                  ],
                                );
                              },
                            ),

                            Builder(
                              builder: (context) {
                                bool isUsingRealCycleTimes =
                                    sl<SharedPreferencesService>()
                                        .shouldUseRealCycleTimes();

                                // callback function that will update the state of this widget when the switch is toggled
                                void onUseRealCycleTimesChanged(bool value) {
                                  setState(() {
                                    isUsingRealCycleTimes = value;
                                  });
                                }

                                return SettingTile(
                                  title: "Use real cycle times",
                                  subtitle:
                                      "Add 5 minutes to your selected cycle time, since the machines often give inaccurate estimates.",
                                  state: isUsingRealCycleTimes
                                      ? TileState.enabled
                                      : TileState.disabled,
                                  children: [
                                    UseRealCycleTimesDefaultSwitch(
                                      onChanged: onUseRealCycleTimesChanged,
                                    ),
                                  ],
                                );
                              },
                            ),

                            // Builder(
                            //   builder: (context) {
                            //     bool canOpenScanner =
                            //         sl<SharedPreferencesService>()
                            //             .shouldShowScannerOnStart();

                            //     void onOpenScannerChanged(bool value) {
                            //       setState(() {
                            //         canOpenScanner = value;
                            //       });
                            //     }

                            //     return SettingTile(
                            //       title: "Open scanner when opening app",
                            //       subtitle:
                            //           "When enabled, the QR code scanner will be active for 5 seconds when you open the app, allowing you to quickly scan the machine QR code.",
                            //       state: canOpenScanner
                            //           ? TileState.enabled
                            //           : TileState.disabled,
                            //       children: [
                            //         OpenScannerDefaultSwitch(
                            //           onChanged: onOpenScannerChanged,
                            //         ),
                            //       ],
                            //     );
                            //   },
                            // ),
                            if (Platform.isAndroid)
                              Builder(
                                builder: (context) {
                                  bool canOpenTimer =
                                      sl<SharedPreferencesService>()
                                          .shouldOpenTimerAfterClaiming();

                                  void onOpenTimerChanged(bool value) {
                                    setState(() {
                                      canOpenTimer = value;
                                    });
                                  }

                                  return SettingTile(
                                    title: "Open timer after claiming",
                                    subtitle:
                                        "Choose whether you want to redirect to the timer screen when claiming.",
                                    state: canOpenTimer
                                        ? TileState.enabled
                                        : TileState.disabled,
                                    children: [
                                      OpenTimerDefaultSwitch(
                                        onChanged: onOpenTimerChanged,
                                      ),
                                    ],
                                  );
                                },
                              ),

                            // Column(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   spacing: 2,
                            //   children: [
                            //     Text(
                            //       "Use real cycle times",
                            //       style: Theme.of(
                            //         context,
                            //       ).textTheme.headlineSmall,
                            //     ),
                            //     RichText(
                            //       text: TextSpan(
                            //         text:
                            //             "Add 5 minutes to your selected cycle time, since the machines often give inaccurate estimates.",
                            //         style: Theme.of(
                            //           context,
                            //         ).textTheme.bodySmall,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // Padding(
                            //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            //   child: Column(
                            //     spacing: 8,
                            //     children: [
                            //       // default cycle time (washer)
                            //       UseRealCycleTimesDefaultSwitch(),
                            //     ],
                            //   ),
                            // ),
                            // Divider(),
                            // Column(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   spacing: 2,
                            //   children: [
                            //     Text(
                            //       "Open scanner when opening app",
                            //       style: Theme.of(
                            //         context,
                            //       ).textTheme.headlineSmall,
                            //     ),
                            //     RichText(
                            //       text: TextSpan(
                            //         text:
                            //             "When enabled, the QR code scanner will be active for 5 seconds when you open the app, allowing you to quickly scan the machine QR code.",
                            //         style: Theme.of(
                            //           context,
                            //         ).textTheme.bodySmall,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // Padding(
                            //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            //   child: Column(
                            //     spacing: 8,
                            //     children: [
                            //       // default cycle time (washer)
                            //       OpenScannerDefaultSwitch(),
                            //     ],
                            //   ),
                            // ),
                            // Divider(),
                            // default cycle time (dryer)
                            // if (Platform.isAndroid)
                            //   Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     spacing: 2,

                            //     children: [
                            //       Text(
                            //         "Open timer after claiming",
                            //         style: Theme.of(
                            //           context,
                            //         ).textTheme.headlineSmall,
                            //       ),
                            //       RichText(
                            //         text: TextSpan(
                            //           text:
                            //               "Choose whether you want to redirect to the timer screen when claiming.",
                            //           style: Theme.of(
                            //             context,
                            //           ).textTheme.bodySmall,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // if (Platform.isAndroid)
                            //   Padding(
                            //     padding: const EdgeInsets.fromLTRB(
                            //       16,
                            //       8,
                            //       16,
                            //       8,
                            //     ),
                            //     child: Column(
                            //       spacing: 8,
                            //       children: [
                            //         // default cycle time (washer)
                            //         OpenTimerDefaultSwitch(),
                            //       ],
                            //     ),
                            //   ),
                            Divider(),
                            Text(
                              "Current build version: ${buildVersion}",
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  AppShellPageController.instance
                                      .showTutorial();
                                },
                                child: Text("Need help? Visit the tutorial"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            //   // onRefresh: () async {
            //   //   // Refresh both subscription and claim cubits
            //   //   await Future.wait([
            //   //     // context.read<SubscriptionCubit>().refreshSubscribedMachines(),
            //   //     // context.read<ClaimCubit>().refreshClaimedMachines(),
            //   //   ]);
            //   // },
            // ),
          );
        },
      ),
    );
  }
}
