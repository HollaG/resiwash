import 'package:flutter/material.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/main.dart';
import 'package:resiwash/theme.dart';

/// Helper class for showing snackbars throughout the app
class SnackbarHelper {
  /// Show a snackbar with optional action button
  ///
  /// [message] - The message to display
  /// [actionLabel] - Optional label for the action button (e.g., "Retry", "Undo")
  /// [onAction] - Optional callback when action button is pressed
  /// [duration] - How long to show the snackbar (default: 4 seconds)
  /// [backgroundColor] - Optional background color
  /// [isError] - If true, uses error styling (red background)
  static void show({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    bool isError = false,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      appLog.e("Snackbar messenger is null");
      return;
    }

    // Clear any existing snackbars
    messenger.clearSnackBars();

    // Determine background color
    Color? bgColor = backgroundColor;
    if (isError && backgroundColor == null) {
      bgColor = Colors.red.shade700;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: bgColor,
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show an error snackbar with retry action
  static void showError({required String message, VoidCallback? onRetry}) {
    show(
      message: message,
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
      isError: true,
    );
  }

  /// Show a success snackbar
  static void showSuccess({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      backgroundColor: Colors.green.shade700,
    );
  }

  /// Show an info snackbar
  static void showInfo({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      backgroundColor: Theme.of(
        scaffoldMessengerKey.currentContext!,
      ).colorScheme.primaryContainer,
    );
  }

  /// Show a warning snackbar
  static void showWarning({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      backgroundColor: Colors.orange.shade700,
    );
  }

  // static void showClaimedMachineIfNotShown({
  //   required String title,
  //   required String description,
  //   required MachineStatus status,
  //   required int secondsTillCompletion,
  //   required String machineId, // for identifying the snackbar
  // }) {
  //   final messenger = scaffoldMessengerKey.currentState;
  //   if (messenger == null) {
  //     appLog.e("Snackbar messenger is null");
  //     return;
  //   }

  //   messenger.showSnackBar(
  //     SnackBar(
  //       key: ValueKey("claimed_machine_$machineId"),
  //       content: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           Center(
  //             child: MachineStatusIndicator(
  //               status: status,
  //               size: BoxSize.large,
  //             ),
  //           ),

  //           Expanded(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               spacing: 4,
  //               children: [Text(title), Text(description)],
  //             ),
  //           ),
  //         ],
  //       ),
  //       duration: Duration(seconds: secondsTillCompletion),
  //       backgroundColor: scaffoldMessengerKey
  //           .currentContext!
  //           .appColors
  //           .accent
  //           .colorContainer,
  //       dismissDirection: DismissDirection.none,

  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }
}
