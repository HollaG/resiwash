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

// class ScanQrScreen extends StatelessWidget {
//   const ScanQrScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Scan QR Code'),
//       ),
//       body: const Center(
//         child: Text(
//           'Scan QR Code',
//           style: TextStyle(fontSize: 24),
//         ),
//       ),
//     );
//   }
// }

/// Implementation of Mobile Scanner example with simple configuration
class MobileScannerSimple extends StatefulWidget {
  /// Constructor for simple Mobile Scanner example
  const MobileScannerSimple({super.key});

  @override
  State<MobileScannerSimple> createState() => _MobileScannerSimpleState();
}

class _MobileScannerSimpleState extends State<MobileScannerSimple>
    with RouteAware {
  Barcode? _barcode;
  String machineId = "";
  String roomId = "";
  bool _navigating = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // User navigated away from this screen
    _controller.stop();
    super.didPushNext();
  }

  @override
  void didPopNext() {
    // User came back to this screen
    _controller.start();
    super.didPopNext();
  }

  Widget _barcodePreview(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
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
    await _controller.stop();
    _navigating = true;

    if (!mounted) return;

    if (machineId.isNotEmpty) {
      // TODO: I want to use PUSH here, but the app does not seem to let me
      // restart the camera scanner when I come back if I use push.
      context.replace(
        Uri(path: AppRoutes.buildMachineDetailRoute(machineId)).toString(),
        // extra: {'machine': widget.machine},
        extra: {'initialAction': InitialPageAction.claim},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    controller: _controller,
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
