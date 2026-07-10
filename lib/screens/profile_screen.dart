import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final roleLabel = _roleLabel(user?.role);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadii.radiusSheet),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(AppColors.surface),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Pengguna',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(AppColors.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileRoleChip(
                  roleLabel: roleLabel,
                  isAdmin: user?.isAdmin == true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _UserInfoTile(roleLabel: roleLabel, email: user?.email),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                shape: const StadiumBorder(),
              ),
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String? role) {
    return switch (role) {
      'admin' => 'Admin',
      'pemilik' => 'Pemilik',
      final value? when value.isNotEmpty => value,
      _ => '-',
    };
  }
}

class _ProfileRoleChip extends StatelessWidget {
  const _ProfileRoleChip({required this.roleLabel, required this.isAdmin});

  final String roleLabel;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: Color(AppColors.surface),
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.storefront_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              roleLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoTile extends StatelessWidget {
  const _UserInfoTile({required this.roleLabel, required this.email});

  final String roleLabel;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_circle_outlined,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Informasi Pengguna',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _UserInfoRow(
              icon: Icons.badge_outlined,
              label: 'Role',
              value: roleLabel,
            ),
            const Divider(height: 1, color: Color(AppColors.hairline)),
            _UserInfoRow(
              icon: Icons.mail_outline,
              label: 'Email',
              value: email,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(AppColors.textSubtle),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value == null || value!.isEmpty ? '-' : value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
