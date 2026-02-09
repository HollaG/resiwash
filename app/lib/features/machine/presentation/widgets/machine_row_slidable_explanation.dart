import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// A demonstration widget showing the Slidable UI structure
/// without business logic - only open/close functionality
class MachineRowSlidableExplanation extends StatefulWidget {
  final Widget child;
  final String machineId;
  final bool enabled;

  // Left action props
  final VoidCallback? onLeftAction;
  final Widget leftIcon;
  final String leftText;
  final Color leftBackgroundColor;
  final Color leftForegroundColor;

  // Right action props
  final VoidCallback? onRightAction;
  final Widget rightIcon;
  final String rightText;
  final Color rightBackgroundColor;
  final Color rightForegroundColor;

  const MachineRowSlidableExplanation({
    super.key,
    required this.child,
    required this.machineId,
    this.enabled = true,
    this.onLeftAction,
    required this.leftIcon,
    required this.leftText,
    required this.leftBackgroundColor,
    required this.leftForegroundColor,
    this.onRightAction,
    required this.rightIcon,
    required this.rightText,
    required this.rightBackgroundColor,
    required this.rightForegroundColor,
  });

  @override
  State<MachineRowSlidableExplanation> createState() =>
      _MachineRowSlidableExplanationState();
}

class _MachineRowSlidableExplanationState
    extends State<MachineRowSlidableExplanation>
    with SingleTickerProviderStateMixin {
  late final SlidableController controller = SlidableController(this);

  Future<void> closeControllerAfterDelay() async {
    await Future.delayed(const Duration(seconds: 1));
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: Key(widget.machineId),
      enabled: widget.enabled,
      closeOnScroll: true,
      controller: controller,

      // Left swipe action
      startActionPane: widget.enabled
          ? ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.3,
              dismissible: DismissiblePane(
                dismissThreshold: 0.4,
                onDismissed: () => {},
                confirmDismiss: () async {
                  // Call the provided callback
                  widget.onLeftAction?.call();
                  closeControllerAfterDelay();
                  return false;
                },
              ),
              children: [
                CustomSlidableAction(
                  onPressed: (context) async {
                    // Call the provided callback
                    widget.onLeftAction?.call();
                  },
                  backgroundColor: widget.leftBackgroundColor,
                  foregroundColor: widget.leftForegroundColor,
                  borderRadius: BorderRadius.circular(8),
                  autoClose: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.leftIcon,
                      const SizedBox(height: 4),
                      Text(
                        widget.leftText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: widget.leftForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,

      // Right swipe action
      endActionPane: widget.enabled
          ? ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              dismissible: DismissiblePane(
                onDismissed: () => {},
                dismissThreshold: 0.4,
                confirmDismiss: () async {
                  // Call the provided callback
                  widget.onRightAction?.call();
                  closeControllerAfterDelay();
                  return false;
                },
              ),
              children: [
                CustomSlidableAction(
                  onPressed: (context) async {
                    // Call the provided callback
                    widget.onRightAction?.call();
                  },
                  backgroundColor: widget.rightBackgroundColor,
                  foregroundColor: widget.rightForegroundColor,
                  borderRadius: BorderRadius.circular(8),
                  autoClose: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.rightIcon,
                      const SizedBox(height: 4),
                      Text(
                        widget.rightText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: widget.rightForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,

      child: widget.child,
    );
  }
}
