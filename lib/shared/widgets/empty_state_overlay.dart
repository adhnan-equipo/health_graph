import 'package:flutter/material.dart';

/// Shared empty state overlay for all health metric charts
/// Provides consistent empty state UI across all chart types
class SharedEmptyStateOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onRetry;
  final Color? backgroundColor;
  final bool animate;

  const SharedEmptyStateOverlay({
    super.key,
    this.message = 'No data available',
    this.icon = Icons.show_chart,
    this.subtitle,
    this.onRetry,
    this.backgroundColor,
    this.animate = true,
  });

  @override
  State<SharedEmptyStateOverlay> createState() =>
      _SharedEmptyStateOverlayState();
}

class _SharedEmptyStateOverlayState extends State<SharedEmptyStateOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.animate) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ));

      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ));

      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      color: widget.backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                widget.message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.8),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!widget.animate) {
      return child;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Predefined empty state configurations for different scenarios
class EmptyStateConfigs {
  static const noData = SharedEmptyStateOverlay(
    icon: Icons.show_chart,
    message: 'No data available',
    subtitle: 'Add some measurements to see your chart',
  );

  static const noDataInRange = SharedEmptyStateOverlay(
    icon: Icons.date_range,
    message: 'No data in selected range',
    subtitle: 'Try selecting a different time period',
  );

  static const loading = SharedEmptyStateOverlay(
    icon: Icons.hourglass_empty,
    message: 'Loading data...',
    animate: false,
  );

  static SharedEmptyStateOverlay error({VoidCallback? onRetry}) {
    return SharedEmptyStateOverlay(
      icon: Icons.error_outline,
      message: 'Failed to load data',
      subtitle: 'Please try again',
      onRetry: onRetry,
    );
  }

  static const syncing = SharedEmptyStateOverlay(
    icon: Icons.sync,
    message: 'Syncing data...',
    subtitle: 'This may take a moment',
    animate: false,
  );
}
