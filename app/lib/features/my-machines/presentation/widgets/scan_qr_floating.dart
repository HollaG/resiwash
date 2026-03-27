import 'dart:async';

import 'package:draggable_float_widget/draggable_float_widget.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/features/machine/presentation/screens/machine_detail_screen.dart';
import 'package:resiwash/router.dart';

class ScanQrFloating extends StatefulWidget {
  const ScanQrFloating({super.key});

  @override
  State<ScanQrFloating> createState() => _ScanQrFloatingState();
}

class _ScanQrFloatingState extends State<ScanQrFloating>
    with WidgetsBindingObserver {
  OverlayEntry? _overlayEntry;
  late StreamController<OperateEvent> eventStreamController;
  bool _wasOnScanQrRoute = false;

  final MobileScannerController controller = MobileScannerController();

  // 5 second timer for users to scan
  Timer? _scanTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    router.routerDelegate.addListener(_handleRouteChanged);
    eventStreamController = StreamController.broadcast();
    _wasOnScanQrRoute = _isOnScanQrRoute();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOverlayForCurrentSession();
    });
  }

  void _handleRouteChanged() {
    if (!mounted) return;

    final isOnScanQrRoute = _isOnScanQrRoute();
    if (isOnScanQrRoute == _wasOnScanQrRoute) {
      return;
    }

    _wasOnScanQrRoute = isOnScanQrRoute;
    if (isOnScanQrRoute) {
      _removePreviousOverlay();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showOverlayForCurrentSession();
    });
  }

  bool _isOnScanQrRoute() {
    final currentPath = router.routeInformationProvider.value.uri.path;
    return currentPath == AppRoutes.scanQr;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showOverlayForCurrentSession();
        });
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _removePreviousOverlay();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.routerDelegate.removeListener(_handleRouteChanged);
    _removePreviousOverlay();
    eventStreamController.close();
    controller.dispose();
    super.dispose();
  }

  _removePreviousOverlay() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlayForCurrentSession() {
    if (_isOnScanQrRoute()) {
      _removePreviousOverlay();
      return;
    }

    _showOverlay();

    // Start the timer once the overlay is shown.
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 5), () {
      _removePreviousOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
      return;
    }

    debugPrint('debug Scanned QR code with value: $rawValue');

    final uri = Uri.parse(rawValue);
    final machineIdParam = uri.queryParameters['machineId'];

    // based on the machineId, redirect the user to the MachineDetailScreen, and
    // also set extra information to popup "claim" option
    await controller.stop();

    if (!mounted) return;

    if (machineIdParam?.isNotEmpty == true) {
      // immediately remove the overlay and stop the timer
      _removePreviousOverlay();
      _scanTimer?.cancel();

      context.replaceNamed(
        AppRoutes.machineDetailName,
        pathParameters: {'machineId': machineIdParam!},
        extra: {'initialAction': InitialPageAction.claim},
      );
    }
  }

  _showOverlay() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final floatWidth = screenWidth * 0.9;
    // ratio: 16:9
    final height = floatWidth * 9 / 16;

    // 1. remove previous overlay
    _removePreviousOverlay();
    // 2. show new overlay
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return DraggableFloatWidget(
          width: floatWidth,
          height: height,
          eventStreamController: eventStreamController,
          config: DraggableFloatWidgetBaseConfig(
            initPositionYInTop: true,
            initPositionYMarginBorder: 32,
            borderTopContainTopBar: false,
            borderBottom: kToolbarHeight + defaultBorderWidth,
            appBarHeight: 0,
            animDuration: const Duration(milliseconds: 100),
          ),
          onTap: () => _removePreviousOverlay(),
          child: SizedBox(
            width: floatWidth,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MobileScanner(
                controller: controller,
                onDetect: (result) {
                  _handleBarcode(result);
                },
              ),
            ),
          ),
        );
      },
    );

    final overlayState =
        router.routerDelegate.navigatorKey.currentState?.overlay ??
        Overlay.maybeOf(context, rootOverlay: true);

    if (overlayState == null) {
      debugPrint('ScanQrFloating: no Overlay available to insert entry.');
      return;
    }

    overlayState.insert(_overlayEntry!);
  }
}
