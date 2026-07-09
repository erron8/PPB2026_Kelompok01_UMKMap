import 'package:flutter/material.dart';

import '../utils/constants.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = _StatusConfig.fromStatus(status, colorScheme);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: config.fill,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 5 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: config.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              config.label,
              style: TextStyle(
                color: config.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.color,
    required this.fill,
  });

  final String label;
  final Color color;
  final Color fill;

  factory _StatusConfig.fromStatus(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'verified':
        return const _StatusConfig(
          label: 'Terverifikasi',
          color: Color(AppColors.statusVerifiedText),
          fill: Color(AppColors.statusVerifiedFill),
        );
      case 'rejected':
        return const _StatusConfig(
          label: 'Ditolak',
          color: Color(AppColors.statusRejectedText),
          fill: Color(AppColors.statusRejectedFill),
        );
      case 'pending':
        return const _StatusConfig(
          label: 'Menunggu Verifikasi',
          color: Color(AppColors.statusPendingText),
          fill: Color(AppColors.statusPendingFill),
        );
      default:
        return _StatusConfig(
          label: status.isEmpty ? 'Status tidak diketahui' : status,
          color: colorScheme.outline,
          fill: colorScheme.surfaceContainerHighest,
        );
    }
  }
}
