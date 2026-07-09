import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = _StatusConfig.fromStatus(status, colorScheme);

    return Chip(
      visualDensity: compact ? VisualDensity.compact : null,
      materialTapTargetSize: compact
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      avatar: Icon(config.icon, size: compact ? 16 : 18, color: config.color),
      label: Text(config.label),
      labelStyle: TextStyle(
        color: config.color,
        fontSize: compact ? 12 : null,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: config.color.withValues(alpha: 0.38)),
      backgroundColor: config.color.withValues(alpha: 0.10),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6)
          : const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _StatusConfig.fromStatus(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'verified':
        return const _StatusConfig(
          label: 'Terverifikasi',
          color: Color(0xFF2E7D32),
          icon: Icons.verified,
        );
      case 'rejected':
        return const _StatusConfig(
          label: 'Ditolak',
          color: Color(0xFFC62828),
          icon: Icons.cancel,
        );
      case 'pending':
        return const _StatusConfig(
          label: 'Menunggu Verifikasi',
          color: Color(0xFFB26A00),
          icon: Icons.schedule,
        );
      default:
        return _StatusConfig(
          label: status.isEmpty ? 'Status tidak diketahui' : status,
          color: colorScheme.outline,
          icon: Icons.help_outline,
        );
    }
  }
}
