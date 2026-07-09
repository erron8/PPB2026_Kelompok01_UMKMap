import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 46,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Pengguna',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(user?.email ?? '-', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: Chip(
              avatar: Icon(
                user?.isAdmin == true
                    ? Icons.admin_panel_settings_outlined
                    : Icons.storefront_outlined,
                size: 18,
              ),
              label: Text(roleLabel),
            ),
          ),
          const SizedBox(height: 24),
          _UserInfoTile(roleLabel: roleLabel, email: user?.email),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: auth.isLoading
                ? null
                : () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
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

class _UserInfoTile extends StatelessWidget {
  const _UserInfoTile({required this.roleLabel, required this.email});

  final String roleLabel;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informasi Pengguna',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _UserInfoRow(label: 'Role', value: roleLabel),
            _UserInfoRow(label: 'Email', value: email),
          ],
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value == null || value!.isEmpty ? '-' : value!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
