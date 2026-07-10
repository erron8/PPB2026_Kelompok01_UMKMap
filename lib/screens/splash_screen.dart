import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final isOffline = auth.startupFailedOffline;

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, size: 80, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                AppConfig.appName,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pendataan UMKM berbasis peta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(
                    AppColors.onSecondary,
                  ).withValues(alpha: 0.75),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              if (isOffline)
                _OfflineRetry(
                  onRetry: () => context.read<AuthProvider>().restoreSession(),
                )
              else
                CircularProgressIndicator(color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineRetry extends StatelessWidget {
  const _OfflineRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final onSecondary = const Color(AppColors.onSecondary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.wifi_off_rounded,
          size: 40,
          color: onSecondary.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 12),
        Text(
          'Tidak ada koneksi internet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Periksa koneksi Anda, lalu coba lagi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onSecondary.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba Lagi'),
        ),
      ],
    );
  }
}
