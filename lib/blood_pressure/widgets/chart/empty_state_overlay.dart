import 'package:flutter/material.dart';

class EmptyStateOverlay extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateOverlay({
    super.key,
    this.message = 'No data available',
    this.icon = Icons.show_chart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
