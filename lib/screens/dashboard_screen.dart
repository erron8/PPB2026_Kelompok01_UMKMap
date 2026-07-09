import 'package:cached_network_image/cached_network_image.dart';
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
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user?.fullName ?? (isGuest ? 'Tamu' : 'Pengguna')}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RoleBadge(role: user?.role ?? 'tamu'),
                  ],
                ),
              ),
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
    final theme = Theme.of(context);
    final (label, icon) = switch (role) {
      'admin' => ('Admin', Icons.admin_panel_settings_outlined),
      'tamu' => ('Tamu', Icons.person_outline),
      _ => ('Pemilik', Icons.storefront_outlined),
    };

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
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
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
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          label: 'Total UMKM',
          value: value.total,
          icon: Icons.storefront,
        ),
        _StatCard(
          label: 'Terverifikasi',
          value: value.verified,
          icon: Icons.verified,
        ),
        _StatCard(
          label: 'Menunggu',
          value: value.pending,
          icon: Icons.schedule,
        ),
        _StatCard(label: 'Ditolak', value: value.rejected, icon: Icons.block),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 22),
            ),
            const Spacer(),
            Text(
              '$value',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(AppColors.textSubtle),
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
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.72,
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
    final colorScheme = theme.colorScheme;
    final isGuest = context.watch<AuthProvider>().isGuest;
    final locked = requiresAuth && isGuest;

    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.radiusCard),
        onTap: () {
          if (locked) {
            showLoginRequiredDialog(context);
          } else {
            GoRouter.of(context).push(route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: colorScheme.onPrimary, size: 26),
                  ),
                  if (locked)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(AppColors.surface),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: colorScheme.primary,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(AppColors.textPrimary),
                  fontWeight: FontWeight.w600,
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
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.login, color: colorScheme.primary),
            ),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(AppColors.textMuted),
                    ),
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
            color: const Color(AppColors.textPrimary),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.radiusCard),
        onTap: () => context.push('/umkm/${umkm.id}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _CompactThumb(url: umkm.fotoUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            umkm.namaUsaha,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status: umkm.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${umkm.kecamatanNama}, ${umkm.kotaNama}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(AppColors.textSubtle),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(AppColors.oliveGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactThumb extends StatelessWidget {
  const _CompactThumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = url;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.square(
        dimension: 44,
        child: imageUrl == null || imageUrl.isEmpty
            ? ColoredBox(
                color: colorScheme.primaryContainer,
                child: Icon(
                  Icons.storefront,
                  color: colorScheme.primary,
                  size: 22,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, _) => ColoredBox(
                  color: colorScheme.primaryContainer,
                  child: const Center(
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, _, _) => ColoredBox(
                  color: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
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
