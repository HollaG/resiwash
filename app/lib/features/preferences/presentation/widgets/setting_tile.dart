import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum TileState { enabled, disabled, intermediate }

class SettingTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final TileState? state;

  final bool initiallyExpanded;

  const SettingTile({
    Key? key,
    required this.title,
    this.subtitle,
    required this.children,
    this.state = TileState.enabled,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant SettingTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.state == TileState.enabled
                ? Colors.green
                : widget.state == TileState.disabled
                ? Colors.transparent
                : Colors.transparent,
          ),
        ),

        // trailing: Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     if (widget.state == TileState.enabled)
        //       Container(
        //         decoration: BoxDecoration(
        //           color: Theme.of(context).colorScheme.primaryContainer,
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //         child: Text(
        //           "Enabled",
        //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
        //             color: Theme.of(context).colorScheme.onPrimary,
        //           ),
        //         ),
        //       )
        //     else if (widget.state == TileState.disabled)
        //       Container(
        //         decoration: BoxDecoration(
        //           // color: Theme.of(context).colorScheme.,
        //           borderRadius: BorderRadius.circular(8),
        //           border: Border.all(
        //             color: Theme.of(
        //               context,
        //             ).colorScheme.onSurfaceVariant.withAlpha(60),
        //             width: 1.5,
        //           ),
        //         ),
        //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //         child: Text(
        //           "Disabled",
        //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
        //             // color: Theme.of(context).colorScheme.onPrimary,
        //           ),
        //         ),
        //       )
        //     else if (widget.state == TileState.intermediate)
        //       SizedBox.shrink(),
        //     // Icon(Icons.remove_circle, color: Colors.orange),
        //   ],
        // ),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        onExpansionChanged: (v) {
          setState(() {
            isExpanded = v;
          });
        },
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              // Text(
              //   widget.title,
              //   style: Theme.of(context).textTheme.headlineSmall,
              // ),
              RichText(
                text: TextSpan(
                  text: widget.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          Column(spacing: 8, children: widget.children),
          Divider(),
        ],
      ),
    );
  }
}
