// lib/utils/tooltip_position.dart
import 'package:flutter/material.dart';

/// A class that represents the position for a tooltip in the heart rate chart
class TooltipPosition {
  final double left;
  final double top;
  final bool showAbove;
  final bool alignLeft; // New property to track alignment direction

  const TooltipPosition({
    required this.left,
    required this.top,
    required this.showAbove,
    this.alignLeft = false, // Default to standard positioning
  });

  /// Calculates the optimal position for a tooltip to ensure it stays within screen bounds
  static TooltipPosition calculate({
    required Offset tapPosition,
    required Size tooltipSize,
    required Size screenSize,
    required EdgeInsets safeArea,
  }) {
    // Check available space on each side
    final spaceRight = screenSize.width - tapPosition.dx - safeArea.right;
    final spaceAbove = tapPosition.dy - safeArea.top;

    // Determine if we need to align left (when close to right edge)
    final needsLeftAlignment =
        spaceRight < (tooltipSize.width * 0.7); // Use 70% threshold

    // Calculate horizontal position
    double left;
    if (needsLeftAlignment) {
      // Position tooltip to the left of the tap point with some padding
      left = tapPosition.dx - tooltipSize.width - 10;
    } else {
      // Center tooltip on tap point (default behavior)
      left = tapPosition.dx - (tooltipSize.width / 2);
    }

    // Determine vertical positioning
    bool showAbove = spaceAbove >= tooltipSize.height + 10;
    double top = showAbove
        ? tapPosition.dy - tooltipSize.height - 10
        : tapPosition.dy + 10;

    // Apply safe area insets and ensure tooltip stays on screen
    final minLeft = safeArea.left + 8;
    final maxLeft = screenSize.width - tooltipSize.width - safeArea.right - 8;
    final minTop = safeArea.top + 8;
    final maxTop = screenSize.height - tooltipSize.height - safeArea.bottom - 8;

    // Clamp to screen bounds
    left = left.clamp(minLeft, maxLeft);
    top = top.clamp(minTop, maxTop);

    return TooltipPosition(
      left: left,
      top: top,
      showAbove: showAbove,
      alignLeft: needsLeftAlignment,
    );
  }

  /// Creates a position where the tooltip displays in the center of the screen
  static TooltipPosition center({
    required Size tooltipSize,
    required Size screenSize,
  }) {
    return TooltipPosition(
      left: (screenSize.width - tooltipSize.width) / 2,
      top: (screenSize.height - tooltipSize.height) / 2,
      showAbove: true,
      alignLeft: false,
    );
  }
}
