import 'dart:async';

import 'package:draggable_float_widget/draggable_float_widget.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/features/machine/presentation/screens/machine_detail_screen.dart';
import 'package:resiwash/router.dart';

class ScanQrFloating extends StatefulWidget {
  const ScanQrFloating({
    super.key,
    required this.currentBranchIndex,
    this.scanQrBranchIndex = 3,
  });

  final int currentBranchIndex;
  final int scanQrBranchIndex;

  @override
  State<ScanQrFloating> createState() => _ScanQrFloatingState();
}

final int overlayCooldownSeconds = 5;

enum _OverlayOpenMode { coldStartOnly, everyResume }

class _ScanQrFloatingState extends State<ScanQrFloating>
    with WidgetsBindingObserver {
  OverlayEntry? _overlayEntry;
  late StreamController<OperateEvent> eventStreamController;
  static const _overlayOpenMode = _OverlayOpenMode.everyResume;

  final MobileScannerController controller = MobileScannerController();

  bool canShowAgain = true;

  // Only ever re-show the overlay if it's been at least 1 minute since the app was last visible
  DateTime lastOpenTime = DateTime.now().subtract(
    Duration(seconds: overlayCooldownSeconds),
  );

  // 5 second timer for users to scan
  Timer? _scanTimer;

  bool _shouldShowOnResume() {
    switch (_overlayOpenMode) {
      case _OverlayOpenMode.coldStartOnly:
        return false;
      case _OverlayOpenMode.everyResume:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    eventStreamController = StreamController.broadcast();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOverlayForCurrentSession();
    });
  }

  @override
  void didUpdateWidget(covariant ScanQrFloating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;

    final wasOnScanQrBranch =
        oldWidget.currentBranchIndex == oldWidget.scanQrBranchIndex;
    final isOnScanQrBranch = _isOnScanQrBranch();

    if (wasOnScanQrBranch == isOnScanQrBranch) {
      return;
    }

    if (isOnScanQrBranch) {
      _removePreviousOverlay();
      return;
    }

    // Do not auto-show when leaving the scan branch.
    return;
  }

  bool _isOnScanQrBranch() {
    print(
      "debug checking if on scan qr branch, currentBranchIndex: ${widget.currentBranchIndex}, scanQrBranchIndex: ${widget.scanQrBranchIndex}",
    );
    return widget.currentBranchIndex == widget.scanQrBranchIndex;
  }

  bool _isClaimingMachine() {
    final currentPath = GoRouterState.of(context).uri.path;
    final _state = GoRouterState.of(context);

    Map<String, dynamic>? extra = _state.extra as Map<String, dynamic>?;
    final shouldClaim =
        _state.uri.queryParameters['claim'] == 'true' ||
        extra?['initialAction'] == InitialPageAction.claim;

    print(
      "debug scanqrfloating checking if we're having initial action of claim ${_state.uri.queryParameters}, extra: $extra, shouldClaim: $shouldClaim",
    );

    if (shouldClaim) {
      return true;
    }
    return currentPath.contains("/machine/") && currentPath.contains("claim");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    print("debug ScanQrFloating observed app lifecycle change: $state");

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_shouldShowOnResume()) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showOverlayForCurrentSession();
        });
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _removePreviousOverlay();

        break;
      case AppLifecycleState.paused:
        _removePreviousOverlay();
        // break;
        canShowAgain = true;
        lastOpenTime = DateTime.now();
        // _removePreviousOverlay();

        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    if (sl<SharedPreferencesService>().shouldShowScannerOnStart() == false) {
      print(
        "debug floating scan qr skipping show overlay since user preference is to not show on start",
      );
      return;
    }

    if (_isOnScanQrBranch()) {
      _removePreviousOverlay();
      return;
    }

    if (_isClaimingMachine()) {
      print(
        "debug floating scan qr skipping show overlay since we're currently claiming a machine",
      );
      return;
    }

    if (!canShowAgain) {
      print(
        "debug floating scan qr skipping show overlay since canShowAgain is false, aka we did not hit paused state",
      );
      return;
    }
    if (DateTime.now().difference(lastOpenTime) <
        Duration(seconds: overlayCooldownSeconds)) {
      print(
        "debug floating scan qr skipping show overlay since last show time is ${DateTime.now().difference(lastOpenTime).inSeconds} seconds ago",
      );
      return;
    }

    _showOverlay();

    // Start the timer once the overlay is shown.
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 5), () {
      _removePreviousOverlay();
    });

    canShowAgain = false;
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
              clipBehavior: Clip.hardEdge,
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

    // update that we've shown
    lastOpenTime = DateTime.now();
  }
}
