import 'package:flutter/material.dart';

class LoadingAndError extends StatelessWidget {
  const LoadingAndError({
    super.key,
    this.isLoading = false,
    this.errorMessage,
    this.emptyMessage,
    this.onRetry,
    this.icon = Icons.inbox_outlined,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? emptyMessage;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final message = errorMessage ?? emptyMessage;
    if (message == null) return const SizedBox.shrink();

    final isError = errorMessage != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline : icon,
              size: 40,
              color: isError ? colorScheme.error : colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isError ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
