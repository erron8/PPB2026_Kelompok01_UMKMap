import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/session_service.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.sessionService = const SessionService(),
  });

  final SessionService sessionService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<SessionSnapshot> _sessionSnapshot;

  @override
  void initState() {
    super.initState();
    _sessionSnapshot = widget.sessionService.snapshot();
  }

  Future<void> _refreshSessionSnapshot() async {
    setState(() {
      _sessionSnapshot = widget.sessionService.snapshot();
    });
    await _sessionSnapshot;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final roleLabel = user?.isAdmin == true ? 'Admin' : 'Pemilik';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: _refreshSessionSnapshot,
        child: ListView(
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
            _SessionInfoTile(snapshot: _sessionSnapshot),
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
      ),
    );
  }
}

class _SessionInfoTile extends StatelessWidget {
  const _SessionInfoTile({required this.snapshot});

  final Future<SessionSnapshot> snapshot;

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
        child: FutureBuilder<SessionSnapshot>(
          future: snapshot,
          builder: (context, state) {
            final data = state.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storage_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Session info',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _SessionRow(label: PrefKeys.userId, value: data?.userId),
                  _SessionRow(label: PrefKeys.role, value: data?.role),
                  _SessionRow(label: PrefKeys.email, value: data?.email),
                  _SessionRow(
                    label: PrefKeys.rememberMe,
                    value: data?.rememberMe?.toString(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.label, required this.value});

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
            width: 128,
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
            ),
          ),
        ],
      ),
    );
  }
}
