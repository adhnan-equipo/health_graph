import 'package:flutter/material.dart';

/// A class that represents the position for a tooltip in the heart rate chart
class TooltipPosition {
  final double left;
  final double top;
  final bool showAbove;

  const TooltipPosition({
    required this.left,
    required this.top,
    required this.showAbove,
  });

  /// Calculates the optimal position for a tooltip to ensure it stays within screen bounds
  static TooltipPosition calculate({
    required Offset tapPosition,
    required Size tooltipSize,
    required Size screenSize,
    required EdgeInsets safeArea,
  }) {
    // Initial position (above the tap point)
    double left = tapPosition.dx - (tooltipSize.width / 2);
    double top = tapPosition.dy - tooltipSize.height - 10;
    bool showAbove = true;

    // Apply safe area insets
    final minLeft = safeArea.left + 8;
    final maxLeft = screenSize.width - tooltipSize.width - safeArea.right - 8;
    final minTop = safeArea.top + 8;
    final maxTop = screenSize.height - tooltipSize.height - safeArea.bottom - 8;

    // Adjust horizontal position to stay within bounds
    left = left.clamp(minLeft, maxLeft);

    // If tooltip would go off the top of the screen, show it below the tap point
    if (top < minTop) {
      top = tapPosition.dy + 10;
      showAbove = false;
    }

    // Final vertical bounds check
    top = top.clamp(minTop, maxTop);

    return TooltipPosition(
      left: left,
      top: top,
      showAbove: showAbove,
    );
  }

  /// Creates a position where the tooltip displays in the center of the screen
  /// Useful for fallback positioning or error states
  static TooltipPosition center({
    required Size tooltipSize,
    required Size screenSize,
  }) {
    return TooltipPosition(
      left: (screenSize.width - tooltipSize.width) / 2,
      top: (screenSize.height - tooltipSize.height) / 2,
      showAbove: true,
    );
  }
}
