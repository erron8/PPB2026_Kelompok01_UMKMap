import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/umkm.dart';
import '../providers/auth_provider.dart';
import '../providers/umkm_provider.dart';
import '../utils/formatters.dart';
import '../widgets/loading_and_error.dart';
import '../widgets/status_chip.dart';

class UmkmDetailScreen extends StatefulWidget {
  const UmkmDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<UmkmDetailScreen> createState() => _UmkmDetailScreenState();
}

class _UmkmDetailScreenState extends State<UmkmDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UmkmProvider>().loadById(widget.id);
    });
  }

  @override
  void didUpdateWidget(covariant UmkmDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<UmkmProvider>().loadById(widget.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UmkmProvider>();
    final umkm = provider.selectedUmkm;

    if (provider.isLoadingDetail && umkm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail UMKM')),
        body: const LoadingAndError(isLoading: true),
      );
    }

    if (umkm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail UMKM')),
        body: LoadingAndError(
          errorMessage: provider.detailErrorMessage ?? 'UMKM tidak ditemukan.',
          onRetry: () => context.read<UmkmProvider>().loadById(widget.id),
        ),
      );
    }

    return _DetailContent(umkm: umkm);
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.umkm});

  final Umkm umkm;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canEdit = auth.isAdmin || auth.user?.id == umkm.ownerId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail UMKM')),
      body: ListView(
        children: [
          _PhotoHeader(umkm: umkm),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            umkm.namaUsaha,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            umkm.kategoriNama ?? 'Kategori ${umkm.kategoriId}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusChip(status: umkm.status),
                  ],
                ),
                const SizedBox(height: 16),
                _ActionButtons(canEdit: canEdit),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Informasi Usaha'),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Pemilik',
                  value: umkm.namaPemilik,
                ),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Alamat',
                  value: Formatters.address(umkm),
                ),
                _InfoRow(
                  icon: Icons.my_location,
                  label: 'Koordinat',
                  value: Formatters.coordinates(umkm.latitude, umkm.longitude),
                ),
                _InfoRow(
                  icon: Icons.update,
                  label: 'Diperbarui',
                  value: Formatters.date(umkm.updatedAt),
                ),
                if (umkm.deskripsi != null && umkm.deskripsi!.trim().isNotEmpty)
                  _InfoRow(
                    icon: Icons.notes_outlined,
                    label: 'Deskripsi',
                    value: umkm.deskripsi!,
                  ),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Lokasi'),
                const SizedBox(height: 8),
                _MiniMap(umkm: umkm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.umkm});

  final Umkm umkm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photoUrl = umkm.fotoUrl;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: photoUrl == null || photoUrl.isEmpty
          ? ColoredBox(
              color: colorScheme.primaryContainer,
              child: Icon(
                Icons.storefront,
                size: 72,
                color: colorScheme.onPrimaryContainer,
              ),
            )
          : CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, _) => ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, _, _) => ColoredBox(
                color: colorScheme.primaryContainer,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Arahkan'),
        ),
        if (canEdit)
          OutlinedButton.icon(
            onPressed: () => context.go('/umkm-form'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.umkm});

  final Umkm umkm;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(umkm.latitude, umkm.longitude);
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 190,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ppb2026.umkmap',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.location_on,
                    size: 44,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
