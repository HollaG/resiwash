import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/area/area_service_locator.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_detail_cubit.dart';
import 'package:resiwash/features/machine/presentation/screens/machine_detail_screen.dart';
import 'package:resiwash/router.dart';
import 'package:resiwash/theme.dart';

/// Implementation of Mobile Scanner example with simple configuration
class MobileScannerSimple extends StatefulWidget {
  /// Constructor for simple Mobile Scanner example
  const MobileScannerSimple({super.key});

  static void showHelpInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What is this?'),
        content: Column(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan the QR code pasted on the machines to claim & mark them as in use by you.',
            ),
            const Text(
              "A timer will be set automatically on your phone and you will be notified once your machine is done.",
            ),

            const Text(
              "Alternatively, you can tap your phone on the Tap icon, below the QR code (NFC must be available and enabled).",
            ),
            Divider(),
            const Text(
              "Please note that QR codes are only available in select locations. If you don't see a QR code on your machine, you can still claim it through the app and receive notifications as normal.",
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

  @override
  State<MobileScannerSimple> createState() => _MobileScannerSimpleState();
}

class _MobileScannerSimpleState extends State<MobileScannerSimple>
    with WidgetsBindingObserver {
  Barcode? _barcode;
  String machineId = "";
  String roomId = "";
  bool _wasVisible = false;
  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
  );

  String errorText = '';

  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();

    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    // Start listening to the barcode events.
    _subscription = controller.barcodes.listen(_handleBarcode);

    // Finally, start the scanner itself.
    unawaited(controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.

    print("debug qr didChangeAppLifecycleState: $state");
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed AND this is the current active page (although we can be in different nav stacks, we only want the current page)
        // Don't forget to resume listening to the barcode events.
        _subscription = controller.barcodes.listen(_handleBarcode);
        final shell = StatefulNavigationShell.of(context);
        if (!controller.value.isRunning && shell.currentIndex == 3) {
          unawaited(controller.start());
        }
      // unawaited(controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    print(
      "debug qr didChangeDependencies, current machineId: $machineId, roomId: $roomId",
    );

    // Restart the scanner when coming back to this page
    // Check if we're visible and the scanner is paused
    // if (mounted && TickerMode.of(context)) {
    //   if (!controller.value.isRunning && controller.value.hasCameraPermission) {
    //     print("debug qr restarting scanner from didChangeDependencies");
    //     unawaited(controller.start());
    //   }
    // }
  }

  @override
  Future<void> dispose() async {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_subscription?.cancel());
    _subscription = null;
    // Dispose the widget itself.
    super.dispose();
    // Finally, dispose of the controller.
    await controller.dispose();

    print("debug qr disposed");
  }

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (!mounted) return;

    Barcode? firstBarcode = barcodes.barcodes.firstOrNull;
    if (firstBarcode == null) {
      return;
    }
    // url format: https://resi-wash.com/manual?roomId=6&machineId=33
    // extract roomId and machineId from the url
    String? rawValue = firstBarcode.rawValue;
    if (rawValue == null) {
      return;
    }

    if (!rawValue.startsWith('https://resi-wash.com/manual')) {
      setState(() {
        errorText = 'Invalid QR code scanned. Please try again.';
      });

      // Reset error text after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            errorText = '';
          });
        }
      });

      return;
    }

    final uri = Uri.parse(rawValue);
    final roomIdParam = uri.queryParameters['roomId'];
    final machineIdParam = uri.queryParameters['machineId'];

    bool shouldReload = false;
    if (roomIdParam != null && roomIdParam != roomId) {
      roomId = roomIdParam;
    }
    if (machineIdParam != null && machineIdParam != machineId) {
      machineId = machineIdParam;
      shouldReload = true;
    }

    // based on the machineId, redirect the user to the MachineDetailScreen, and
    // also set extra information to popup "claim" option
    await controller.stop();

    if (!mounted) return;

    if (machineId.isNotEmpty) {
      context.replaceNamed(
        AppRoutes.machineDetailName,
        pathParameters: {'machineId': machineId},
        extra: {'initialAction': InitialPageAction.claim},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = TickerMode.of(context);

    // Detect visibility changes
    if (isVisible && !_wasVisible) {
      // Became visible - restart scanner
      print("debug qr became visible, restarting scanner");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !controller.value.isRunning &&
            controller.value.hasCameraPermission) {
          unawaited(controller.start());
        }
      });
    } else if (!isVisible && _wasVisible) {
      // Became invisible - stop scanner
      print("debug qr became invisible, stopping scanner");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.value.isRunning) {
          unawaited(controller.stop());
        }
      });
    }

    _wasVisible = isVisible;

    return BlocProvider(
      create: (context) =>
          MachineDetailCubit(getMachineUseCase: sl<GetMachineUseCase>()),
      child: Scaffold(
        appBar: AppBarComponent(actions: [], title: "Scan QR Code"),
        // backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(48.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: MobileScanner(
                    onDetect: _handleBarcode,
                    controller: controller,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      if (errorText.isNotEmpty)
                        Text(
                          errorText,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      Text(
                        "Scan a ResiWash QR code to claim & mark a machine as in use by you.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(48, 0, 48, 0),

                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          Text("Automatic timer notifications "),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // BlocConsumer<MachineDetailCubit, MachineDetailState>(
              //   listener: (context, state) {
              //     print("MachineDetailState changed: $state");
              //   },
              //   builder: (context, state) {
              //     if (state is MachineDetailLoading) {
              //       return CircularProgressIndicator();
              //     } else if (state is MachineDetailError) {
              //       return Text("Error: ${state.message}");
              //     } else if (state is MachineDetailLoaded) {
              //       final machine = state.machine;
              //       return Column(
              //         children: [
              //           Text(
              //             "Machine: ${machine.name}",
              //             style: Theme.of(context).textTheme.headlineSmall,
              //           ),
              //           Text("Status: ${machine.currentStatus}"),
              //           Text("Room ID: $roomId"),
              //           Text("Machine ID: $machineId"),
              //         ],
              //       );
              //     }
              //     return _barcodePreview(_barcode);
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
