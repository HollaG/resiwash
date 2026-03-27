import 'dart:async';

import 'package:draggable_float_widget/draggable_float_widget.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrFloating extends StatefulWidget {
  const ScanQrFloating({super.key});

  @override
  State<ScanQrFloating> createState() => _ScanQrFloatingState();
}

class _ScanQrFloatingState extends State<ScanQrFloating> {
  OverlayEntry? _overlayEntry;
  bool _showDraggableFloat = false;
  late StreamController<OperateEvent> eventStreamController;

  @override
  void initState() {
    print("debug ScanQrFloating initState");
    super.initState();
    eventStreamController = StreamController.broadcast();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOverlay();
    });
  }

  @override
  void dispose() {
    _removePreviousOverlay();
    eventStreamController.close();
    super.dispose();
  }

  _removePreviousOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget build(BuildContext context) {
    return Container();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text("Overlay Mode", style: TextStyle(color: Colors.white)),
  //       actions: [
  //         Padding(
  //           padding: EdgeInsets.only(right: 12),
  //           child: InkWell(
  //             onTap: () {
  //               if (_showDraggableFloat) {
  //                 _removePreviousOverlay();
  //               } else {
  //                 _showOverlay();
  //               }
  //               setState(() {
  //                 _showDraggableFloat = !_showDraggableFloat;
  //               });
  //             },
  //             child: Icon(
  //               _showDraggableFloat
  //                   ? Icons.amp_stories_rounded
  //                   : Icons.amp_stories_outlined,
  //               color: Colors.white,
  //               size: 28,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //     backgroundColor: Colors.grey,
  //     body: widget.listView,
  //   );
  // }

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
                onDetect: (result) {
                  print(result.barcodes.first.rawValue);
                },
              ),
            ),
          ),
        );
      },
    );

    /// Warning: context cannot be the context of MaterialApp
    Overlay.of(context)?.insert(_overlayEntry!);
  }
}
