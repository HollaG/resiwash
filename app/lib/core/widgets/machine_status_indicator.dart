import 'package:flutter/material.dart';
import 'package:resiwash/features/machine/data/models/machine_model.dart';
import 'package:resiwash/theme.dart';

enum BoxSize { small, medium, large }

class MachineStatusIndicator extends StatelessWidget {
  final MachineStatus? status;
  final BoxSize size;
  final bool showDiagonal; // new variable
  const MachineStatusIndicator({
    super.key,
    this.status,
    this.size = BoxSize.medium,
    this.showDiagonal = false,
  });

  @override
  Widget build(BuildContext context) {
    // medium = 16, large = 24, small = 12
    double dimension;
    switch (size) {
      case BoxSize.small:
        dimension = 12;
        break;
      case BoxSize.medium:
        dimension = 16;
        break;
      case BoxSize.large:
        dimension = 24;
        break;
    }

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: getIndicatorColor(context, status),
        // color: context.success.color,
        borderRadius: BorderRadius.circular(4),
        border: status == MachineStatus.finishing
            ? Border.all(
                color: getIndicatorColor(context, MachineStatus.available),
                width: 2,
              )
            : null,
      ),
    );
  }

  static Color getIndicatorColor(BuildContext context, MachineStatus? status) {
    switch (status) {
      case MachineStatus.available:
        // Use theme.success color
        return context.success.colorContainer;
      case MachineStatus.inUse:
        // Use the new inUse color we added
        return context.inUse.colorContainer;
      case MachineStatus.hasIssues:
        // Use the unknown/tertiary color (495057)
        return const Color(0xff495057);
      case null:
        return const Color(0xff495057);
      default:
        return const Color(0xff495057);
    }
  }

  static Color getTextColor(BuildContext context, MachineStatus? status) {
    switch (status) {
      case MachineStatus.available:
        return context.success.color;
      case MachineStatus.inUse:
        return context.inUse.color;
      case MachineStatus.hasIssues:
        return const Color(0xff212529);
      case null:
        return const Color(0xff212529);
      default:
        return const Color(0xff212529);
    }
  }

  static Color getBackgroundColor(BuildContext context, MachineStatus? status) {
    switch (status) {
      case MachineStatus.available:
        return context.success.color;
      case MachineStatus.inUse:
        return context.inUse.color;
      case MachineStatus.hasIssues:
        return const Color(0xffCED4DA);
      case null:
        return const Color(0xffCED4DA);
      default:
        return const Color(0xffCED4DA);
    }
  }

  static Color getOnContainerColor(
    BuildContext context,
    MachineStatus? status,
  ) {
    switch (status) {
      case MachineStatus.available:
        return context.success.onColor;
      case MachineStatus.inUse:
        return context.inUse.onColor;
      case MachineStatus.hasIssues:
        return const Color(0xffDEE2E6);
      case null:
        return const Color(0xffDEE2E6);
      default:
        return const Color(0xffDEE2E6);
    }
  }
}

class _DiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffffffff)
      ..strokeWidth = 2;

    // First diagonal (top-left to bottom-right)
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);

    // Second diagonal (top-right to bottom-left)
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
