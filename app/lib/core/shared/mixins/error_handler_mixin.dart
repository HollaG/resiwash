import 'package:flutter/material.dart';

mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  /// Shows an error message with optional retry action
  void showErrorMessage(
    String message, {
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        action: onRetry != null
            ? SnackBarAction(
                label: retryLabel,
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Shows a success message
  void showSuccessMessage(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  /// Shows an info message
  void showInfoMessage(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
