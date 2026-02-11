import 'package:flutter/material.dart';
import 'package:resiwash/main.dart';

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
    if (messenger == null) return;

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
      backgroundColor: Colors.blue.shade700,
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
}
