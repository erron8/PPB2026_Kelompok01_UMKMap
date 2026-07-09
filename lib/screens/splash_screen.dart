import 'package:flutter/material.dart';

import '../utils/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: Center(
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
              style: TextStyle(
                color: const Color(
                  AppColors.onSecondary,
                ).withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
