import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown when a guest taps a feature that requires signing in.
Future<void> showLoginRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Perlu Masuk'),
      content: const Text(
        'Fitur ini hanya tersedia untuk pengguna yang sudah masuk. '
        'Masuk terlebih dahulu untuk melanjutkan.',
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
    ),
  );
}
