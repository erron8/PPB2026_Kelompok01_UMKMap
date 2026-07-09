import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/umkm.dart';
import '../providers/auth_provider.dart';
import '../providers/umkm_provider.dart';
import '../services/umkm_service.dart';
import '../utils/constants.dart';
import '../widgets/login_required_dialog.dart';
import '../widgets/status_chip.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboardData());
  }

  Future<void> _loadDashboardData() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final ownerId = user.isAdmin ? null : user.id;
    final provider = context.read<UmkmProvider>();
    // Await every fetch so the pull-to-refresh spinner stays until the data
    // actually lands instead of retracting immediately.
    await Future.wait([
      provider.loadDashboardStats(ownerId: ownerId),
      provider.loadDashboardRecent(ownerId: ownerId),
      if (user.isAdmin) provider.loadPendingVerification(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<UmkmProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Profil',
            onPressed: isGuest
                ? () => showLoginRequiredDialog(context)
                : () => GoRouter.of(context).push('/profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Halo, ${user?.fullName ?? (isGuest ? 'Tamu' : 'Pengguna')}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _RoleBadge(role: user?.role ?? 'tamu'),
              ],
            ),
            const SizedBox(height: 20),
            if (!isGuest) ...[
              _StatsSection(
                stats: provider.stats,
                isLoading: provider.isLoadingStats,
                errorMessage: provider.statsErrorMessage,
                onRetry: _loadDashboardData,
              ),
              const SizedBox(height: 20),
            ],
            const _MenuGrid(),
            if (isGuest) ...[
              const SizedBox(height: 20),
              const _GuestPrompt(),
            ] else ...[
              if (auth.isAdmin) ...[
                const SizedBox(height: 24),
                _UmkmSection(
                  title: 'Menunggu Verifikasi',
                  items: provider.pendingVerificationItems,
                  isLoading: provider.isLoadingPendingVerification,
                  errorMessage: provider.pendingVerificationErrorMessage,
                  emptyMessage: 'Tidak ada UMKM yang menunggu verifikasi.',
                  onRetry: () =>
                      context.read<UmkmProvider>().loadPendingVerification(),
                ),
              ],
              const SizedBox(height: 24),
              _UmkmSection(
                title: 'UMKM Terbaru',
                items: provider.dashboardRecentItems,
                isLoading: provider.isLoadingDashboardRecent,
                errorMessage: provider.dashboardRecentErrorMessage,
                emptyMessage: auth.isAdmin
                    ? 'Belum ada data UMKM.'
                    : 'Anda belum memiliki data UMKM.',
                onRetry: () => context.read<UmkmProvider>().loadDashboardRecent(
                  ownerId: user?.isAdmin == true ? null : user?.id,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, icon) = switch (role) {
      'admin' => ('Admin', Icons.admin_panel_settings_outlined),
      'tamu' => ('Tamu', Icons.person_outline),
      _ => ('Pemilik', Icons.storefront_outlined),
    };

    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: colorScheme.primaryContainer,
      side: BorderSide.none,
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.stats,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final DashboardStats? stats;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && stats == null) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && stats == null) {
      return _InlineError(message: errorMessage!, onRetry: onRetry);
    }

    final value =
        stats ??
        const DashboardStats(total: 0, verified: 0, pending: 0, rejected: 0);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _StatCard(
          label: 'Total UMKM',
          value: value.total,
          icon: Icons.storefront,
          color: Theme.of(context).colorScheme.primary,
        ),
        _StatCard(
          label: 'Terverifikasi',
          value: value.verified,
          icon: Icons.verified,
          color: const Color(AppColors.statusVerifiedText),
        ),
        _StatCard(
          label: 'Menunggu',
          value: value.pending,
          icon: Icons.schedule,
          color: const Color(AppColors.statusPendingText),
        ),
        _StatCard(
          label: 'Ditolak',
          value: value.rejected,
          icon: Icons.cancel,
          color: const Color(AppColors.statusRejectedText),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.15,
      children: const [
        _MenuTile(title: 'Daftar UMKM', icon: Icons.list_alt, route: '/umkm'),
        _MenuTile(title: 'Peta', icon: Icons.map_outlined, route: '/map'),
        _MenuTile(
          title: 'Tambah UMKM',
          icon: Icons.add_business,
          route: '/umkm-form',
          requiresAuth: true,
        ),
        _MenuTile(
          title: 'Profil',
          icon: Icons.person_outline,
          route: '/profile',
          requiresAuth: true,
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.icon,
    required this.route,
    this.requiresAuth = false,
  });

  final String title;
  final IconData icon;
  final String route;
  final bool requiresAuth;

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
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          final isGuest = context.read<AuthProvider>().isGuest;
          if (requiresAuth && isGuest) {
            showLoginRequiredDialog(context);
          } else {
            GoRouter.of(context).push(route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt();

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anda masuk sebagai tamu.',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masuk untuk menambah UMKM dan mengelola profil Anda.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => GoRouter.of(context).go('/login'),
                    child: const Text('Masuk'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UmkmSection extends StatelessWidget {
  const _UmkmSection({
    required this.title,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.emptyMessage,
    required this.onRetry,
  });

  final String title;
  final List<Umkm> items;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading && items.isEmpty)
          const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (errorMessage != null && items.isEmpty)
          _InlineError(message: errorMessage!, onRetry: onRetry)
        else if (items.isEmpty)
          _EmptyMessage(message: emptyMessage)
        else
          ...items.map((item) => _CompactUmkmTile(umkm: item)),
      ],
    );
  }
}

class _CompactUmkmTile extends StatelessWidget {
  const _CompactUmkmTile({required this.umkm});

  final Umkm umkm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: () => context.push('/umkm/${umkm.id}'),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.storefront,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          umkm.namaUsaha,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${umkm.kecamatanNama}, ${umkm.kotaNama}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: StatusChip(status: umkm.status, compact: true),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(message, textAlign: TextAlign.center)),
      ),
    );
  }
}
