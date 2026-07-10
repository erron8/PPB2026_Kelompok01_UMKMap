import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown when a guest taps a feature that requires signing in.
Future<void> showLoginRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);

      return AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Perlu Masuk'),
          ],
        ),
        content: const Text(
          'Fitur ini hanya tersedia untuk pengguna yang sudah masuk. '
          'Masuk terlebih dahulu untuk melanjutkan.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () {
              final router = GoRouter.of(dialogContext);
              Navigator.of(dialogContext).pop();
              router.go('/login');
            },
            child: const Text('Masuk'),
          ),
        ],
      );
    },
  );
}
