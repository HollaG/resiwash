import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocErrorHandler<B extends StateStreamable<S>, S>
    extends StatelessWidget {
  final Widget child;
  final bool Function(S state) isErrorState;
  final String Function(S state) getErrorMessage;
  final VoidCallback? onRetry;
  final String retryLabel;

  const BlocErrorHandler({
    super.key,
    required this.child,
    required this.isErrorState,
    required this.getErrorMessage,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listener: (context, state) {
        if (isErrorState(state)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(getErrorMessage(state))),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              action: onRetry != null
                  ? SnackBarAction(
                      label: retryLabel,
                      textColor: Colors.white,
                      onPressed: onRetry!,
                    )
                  : null,
            ),
          );
        }
      },
      child: child,
    );
  }
}
