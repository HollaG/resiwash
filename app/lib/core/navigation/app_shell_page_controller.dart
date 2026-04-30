import 'package:flutter/widgets.dart';

class AppShellPageController {
  AppShellPageController._();

  static final AppShellPageController instance = AppShellPageController._();

  PageController? _controller;

  void attach(PageController controller) {
    _controller = controller;
  }

  void detach() {
    _controller = null;
  }

  Future<void> showTutorial() async {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;

    await controller.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> showApp() async {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;

    await controller.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
