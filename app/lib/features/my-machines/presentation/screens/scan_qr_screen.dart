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

/// Implementation of Mobile Scanner example with simple configuration
class MobileScannerSimple extends StatefulWidget {
  /// Constructor for simple Mobile Scanner example
  const MobileScannerSimple({super.key});

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

  static String INFO_DEFAULT =
      'Scan a ResiWash QR code to mark a machine as in use by you.';
  String infoText = INFO_DEFAULT;

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
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = controller.barcodes.listen(_handleBarcode);

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
        infoText = 'Invalid QR code scanned. Please try again.';
      });

      // Reset info text after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            infoText = INFO_DEFAULT;
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
      final uri = Uri(
        path: '/machines/$machineId',
        queryParameters: {
          'roomIds[]': [roomId],
          'types[]': ['washer', 'dryer'],
        },
      );

      context.go(
        uri.toString(),
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
                  child: Text(
                    infoText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
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
