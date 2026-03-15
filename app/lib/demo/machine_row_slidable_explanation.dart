import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/core/widgets/machine_status_indicator.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/theme.dart';

enum PeekState { left, right, closed }

/// A demonstration widget showing the Slidable UI structure
/// with hardcoded demo values - ready to use anywhere in the app
class MachineRowSlidableExplanation extends StatefulWidget {
  final PeekState initialPeekState;
  const MachineRowSlidableExplanation({
    super.key,
    this.initialPeekState = PeekState.closed,
  });

  @override
  State<MachineRowSlidableExplanation> createState() =>
      _MachineRowSlidableExplanationState();
}

class _MachineRowSlidableExplanationState
    extends State<MachineRowSlidableExplanation>
    with SingleTickerProviderStateMixin {
  late final SlidableController controller = SlidableController(this);

  @override
  void initState() {
    super.initState();
    // Open the slidable to the initial peek state after 0.75 seconds
    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      switch (widget.initialPeekState) {
        case PeekState.left:
          controller.openStartActionPane();
          break;
        case PeekState.right:
          controller.openEndActionPane();
          break;
        case PeekState.closed:
          // Do nothing, stays closed
          break;
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> closeControllerAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: const Key('demo_machine'),
      enabled: true,
      closeOnScroll: true,
      controller: controller,

      // Left swipe action (Claim)
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.6,
        dismissible: DismissiblePane(
          dismissThreshold: 0.4,
          onDismissed: () {},
          confirmDismiss: () async {
            // Demo action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demo: Claim action triggered'),
                duration: Duration(seconds: 2),
              ),
            );
            closeControllerAfterDelay();
            return false;
          },
        ),
        children: [
          CustomSlidableAction(
            onPressed: (context) async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demo: Claim action triggered'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            borderRadius: BorderRadius.circular(8),
            autoClose: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_alt_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 4),
                Text(
                  'Use this machine',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.6,
        dismissible: DismissiblePane(
          dismissThreshold: 0.4,
          onDismissed: () {},
          confirmDismiss: () async {
            // Demo action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demo: Claim action triggered'),
                duration: Duration(seconds: 2),
              ),
            );
            closeControllerAfterDelay();
            return false;
          },
        ),
        children: [
          CustomSlidableAction(
            onPressed: (context) async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demo: Claim action triggered'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            borderRadius: BorderRadius.circular(8),
            autoClose: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_alt_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 4),
                Text(
                  'Use this machine',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Right swipe action (Subscribe)
      // endActionPane: ActionPane(
      //   motion: const BehindMotion(),
      //   extentRatio: 0.4,
      //   dismissible: DismissiblePane(
      //     onDismissed: () {},
      //     dismissThreshold: 0.4,
      //     confirmDismiss: () async {
      //       // Demo action
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(
      //           content: Text('Demo: Subscribe action triggered'),
      //           duration: Duration(seconds: 2),
      //         ),
      //       );
      //       closeControllerAfterDelay();
      //       return false;
      //     },
      //   ),
      //   children: [
      //     CustomSlidableAction(
      //       onPressed: (context) async {
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           const SnackBar(
      //             content: Text('Demo: Subscribe action triggered'),
      //             duration: Duration(seconds: 2),
      //           ),
      //         );
      //       },
      //       backgroundColor: context.accent.colorContainer,
      //       foregroundColor: Theme.of(context).colorScheme.secondary,
      //       borderRadius: BorderRadius.circular(8),
      //       autoClose: true,
      //       child: Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: [
      //           Icon(
      //             Icons.notification_add,
      //             color: Theme.of(context).colorScheme.secondary,
      //           ),
      //           const SizedBox(height: 4),
      //           Text(
      //             'Subscribe',
      //             style: Theme.of(context).textTheme.labelSmall?.copyWith(
      //               color: Theme.of(context).colorScheme.secondary,
      //             ),
      //           ),
      //         ],
      //       ),
      //     ),
      //   ],
      // ),

      // Demo machine row content
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demo: Machine row tapped'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Text('Example', style: Theme.of(context).textTheme.labelMedium),
              Expanded(
                child: Text(
                  '@ Example Room',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
          subtitle: Text(
            "Swipe to mark as in use by you",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MachineStatusIndicator.getTextColor(
                context,
                MachineStatus.unknown,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          trailing: AssetIcons.dryerIcon(context),
          leading: MachineStatusIndicator(status: MachineStatus.unknown),
        ),
      ),
    );
  }
}
