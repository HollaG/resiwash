import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/features/machine/presentation/screens/machine_detail_screen.dart';
import 'package:resiwash/router.dart';

class ScanQrHome extends StatefulWidget {
  const ScanQrHome({super.key});

  @override
  State<ScanQrHome> createState() => _ScanQrHomeState();
}

final int overlayCooldownSeconds = 5;

enum _OverlayOpenMode { coldStartOnly, everyResume }

class _ScanQrHomeState extends State<ScanQrHome> with WidgetsBindingObserver {
  bool shouldShow = false;

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
    router.routerDelegate.addListener(_handleRouteChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showOverlayForCurrentSession();
    });
  }

  bool _isOnHomeRoute() {
    final path = router.routeInformationProvider.value.uri.path;
    return path == AppRoutes.home;
  }

  void _handleRouteChanged() {
    if (!mounted) return;

    if (!_isOnHomeRoute()) {
      _removePreviousOverlay();
      return;
    }

    _showOverlayForCurrentSession();
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
    router.routerDelegate.removeListener(_handleRouteChanged);
    _removePreviousOverlay(updateState: false);
    controller.dispose();
    super.dispose();
  }

  void _removePreviousOverlay({bool updateState = true}) {
    _scanTimer?.cancel();
    _scanTimer = null;

    if (!updateState || !mounted) {
      shouldShow = false;
      return;
    }

    setState(() {
      shouldShow = false;
    });
  }

  void _showOverlayForCurrentSession() {
    if (!_isOnHomeRoute()) {
      _removePreviousOverlay();
      return;
    }

    if (sl<SharedPreferencesService>().shouldShowScannerOnStart() == false) {
      print(
        "debug floating scan qr skipping show overlay since user preference is to not show on start",
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

    // _showOverlay();

    if (!mounted) return;
    setState(() {
      shouldShow = true;
    });

    // Start the timer once the overlay is shown.
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 5), () {
      _removePreviousOverlay();
    });

    canShowAgain = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnHomeRoute() || !shouldShow) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final floatWidth = screenWidth;
    // ratio: 16:9
    final height = MediaQuery.of(context).padding.top + kToolbarHeight + 100;

    return SizedBox(
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

  // _showOverlay() {

  //   // 1. remove previous overlay
  //   _removePreviousOverlay();
  //   // 2. show new overlay
  //   _overlayEntry = OverlayEntry(
  //     builder: (context) {
  //       return DraggableFloatWidget(
  //         width: floatWidth,
  //         height: height,
  //         eventStreamController: eventStreamController,
  //         config: DraggableFloatWidgetBaseConfig(
  //           initPositionYInTop: true,
  //           initPositionYMarginBorder: 32,
  //           borderTopContainTopBar: false,
  //           borderBottom: kToolbarHeight + defaultBorderWidth,
  //           appBarHeight: 0,
  //           animDuration: const Duration(milliseconds: 100),
  //         ),
  //         onTap: () => _removePreviousOverlay(),
  //         child: SizedBox(
  //           width: floatWidth,
  //           height: height,
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color: Theme.of(context).colorScheme.secondaryContainer,
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             clipBehavior: Clip.hardEdge,
  //             child: MobileScanner(
  //               controller: controller,
  //               onDetect: (result) {
  //                 _handleBarcode(result);
  //               },
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );

  //   final overlayState =
  //       router.routerDelegate.navigatorKey.currentState?.overlay ??
  //       Overlay.maybeOf(context, rootOverlay: true);

  //   if (overlayState == null) {
  //     debugPrint('ScanQrFloating: no Overlay available to insert entry.');
  //     return;
  //   }

  //   overlayState.insert(_overlayEntry!);

  //   // update that we've shown
  //   lastOpenTime = DateTime.now();
  // }
}
