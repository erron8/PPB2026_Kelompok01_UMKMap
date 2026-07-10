import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/umkm.dart';
import '../providers/auth_provider.dart';
import '../providers/umkm_provider.dart';
import '../services/compass_service.dart';
import '../services/location_service.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';
import '../widgets/compass_arrow.dart';
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
    final isOwner = auth.user?.id == umkm.ownerId;
    final canEdit = auth.isAdmin || isOwner;
    final canVerify = !isOwner && (auth.isAdmin || (auth.user != null && auth.user!.poin > 200));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail UMKM')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _PhotoHeader(umkm: umkm),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(AppColors.background),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.radiusSheet),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
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
                                  color: const Color(AppColors.textPrimary),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                umkm.kategoriNama ??
                                    'Kategori ${umkm.kategoriId}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
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
                    _ActionButtons(
                      umkm: umkm,
                      canEdit: canEdit,
                      canVerify: canVerify,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Informasi Usaha'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      children: [
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
                          value: Formatters.coordinates(
                            umkm.latitude,
                            umkm.longitude,
                          ),
                        ),
                        _InfoRow(
                          icon: Icons.update,
                          label: 'Diperbarui',
                          value: Formatters.date(umkm.updatedAt),
                        ),
                        if (umkm.deskripsi != null &&
                            umkm.deskripsi!.trim().isNotEmpty)
                          _InfoRow(
                            icon: Icons.notes_outlined,
                            label: 'Deskripsi',
                            value: umkm.deskripsi!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Lokasi'),
                    const SizedBox(height: 8),
                    _MiniMap(umkm: umkm),
                  ],
                ),
              ),
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

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          photoUrl == null || photoUrl.isEmpty
              ? ColoredBox(
                  color: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.storefront,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => ColoredBox(
                    color: colorScheme.primaryContainer,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, _, _) => ColoredBox(
                    color: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1],
                colors: [
                  Colors.transparent,
                  const Color(
                    AppColors.onPrimaryContainer,
                  ).withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.umkm,
    required this.canEdit,
    required this.canVerify,
  });

  final Umkm umkm;
  final bool canEdit;
  final bool canVerify;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UmkmProvider>();
    final isBusy = provider.isDeleting || provider.isChangingStatus;
    final colorScheme = Theme.of(context).colorScheme;
    final tonalStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.primary,
      shape: const StadiumBorder(),
    );
    final destructiveStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      foregroundColor: colorScheme.error,
      side: BorderSide(color: colorScheme.error),
      shape: const StadiumBorder(),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _showCompassSheet(context),
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Arahkan'),
        ),
        if (canEdit)
          FilledButton.tonalIcon(
            style: tonalStyle,
            onPressed: isBusy
                ? null
                : () => context.push('/umkm-form', extra: umkm),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        if (canEdit)
          OutlinedButton.icon(
            style: destructiveStyle,
            onPressed: isBusy ? null : () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus'),
          ),
        if (canVerify && umkm.status != 'verified')
          FilledButton.tonalIcon(
            style: tonalStyle,
            onPressed: isBusy
                ? null
                : () => _setStatus(context, 'verified', 'UMKM diverifikasi.'),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Verifikasi'),
          ),
        if (canVerify && umkm.status != 'rejected')
          OutlinedButton.icon(
            style: destructiveStyle,
            onPressed: isBusy
                ? null
                : () => _setStatus(context, 'rejected', 'UMKM ditolak.'),
            icon: const Icon(Icons.block_outlined),
            label: const Text('Tolak'),
          ),
      ],
    );
  }

  Future<void> _showCompassSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CompassNavigationSheet(umkm: umkm),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus UMKM'),
          content: const Text(
            'Hapus UMKM ini? Tindakan tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<UmkmProvider>();
    final deleted = await provider.deleteUmkm(umkm.id);
    if (!context.mounted) return;

    if (deleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('UMKM dihapus.')));
      context.go('/umkm');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.mutationErrorMessage ?? 'Gagal menghapus UMKM.'),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    String status,
    String successMessage,
  ) async {
    final provider = context.read<UmkmProvider>();
    final updated = await provider.setStatus(id: umkm.id, status: status);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated == null
              ? provider.mutationErrorMessage ??
                    'Gagal memperbarui status UMKM.'
              : successMessage,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<_InfoRow> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(height: 1, color: Color(AppColors.hairline)),
            ],
          ],
        ),
      ),
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: const Color(AppColors.textPrimary),
        fontWeight: FontWeight.w800,
      ),
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
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
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
                  value,
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

class _MiniMap extends StatefulWidget {
  const _MiniMap({required this.umkm});

  final Umkm umkm;

  @override
  State<_MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<_MiniMap> {
  bool _tileErrorVisible = false;
  int _tileRetryKey = 0;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(widget.umkm.latitude, widget.umkm.longitude);
    final colorScheme = Theme.of(context).colorScheme;
    final markerColor = Color(AppColors.markerPalette.first);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.radiusCard),
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
                    key: ValueKey(_tileRetryKey),
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ppb2026.umkmap',
                    tileProvider: NetworkTileProvider(silenceExceptions: true),
                    errorTileCallback: (_, _, _) {
                      if (!_tileErrorVisible && mounted) {
                        setState(() => _tileErrorVisible = true);
                      }
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 46,
                        height: 46,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 48,
                              color: Color(AppColors.surface),
                            ),
                            Icon(
                              Icons.location_on,
                              size: 44,
                              color: markerColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_tileErrorVisible)
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Material(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadii.radiusPill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tidak ada koneksi internet',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _tileRetryKey++;
                              _tileErrorVisible = false;
                            });
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompassNavigationSheet extends StatefulWidget {
  const _CompassNavigationSheet({required this.umkm});

  final Umkm umkm;

  @override
  State<_CompassNavigationSheet> createState() =>
      _CompassNavigationSheetState();
}

class _CompassNavigationSheetState extends State<_CompassNavigationSheet> {
  static const _arrivalRadiusMeters = 15.0;
  static const _lowHeadingAccuracyDegrees = 20.0;

  final _compassService = const CompassService();
  final _locationService = const LocationService();

  StreamSubscription<CompassReading>? _compassSubscription;
  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _currentPoint;
  double? _heading;
  double? _headingAccuracy;
  String? _errorMessage;
  bool _isLoadingLocation = true;
  bool _compassStarted = false;

  LatLng get _targetPoint =>
      LatLng(widget.umkm.latitude, widget.umkm.longitude);

  @override
  void initState() {
    super.initState();
    _startCompass();
    _startLocation();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final availability = await _locationService.ensurePermissionAndService();
      if (availability != LocationAvailability.ready) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = LocationService.messageFor(availability);
        });
        return;
      }

      final current = await _locationService.current();
      if (!mounted) return;
      setState(() {
        _currentPoint = current;
        _isLoadingLocation = false;
        _errorMessage = null;
      });

      await _locationSubscription?.cancel();
      _locationSubscription = _locationService.stream().listen(
        (point) {
          if (!mounted) return;
          setState(() {
            _currentPoint = point;
            _errorMessage = null;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Gagal memperbarui lokasi langsung.';
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _errorMessage = 'Gagal mengambil lokasi saat ini.';
      });
    }
  }

  void _startCompass() {
    _compassSubscription = _compassService.readings().listen(
      (reading) {
        if (!mounted) return;
        setState(() {
          _compassStarted = true;
          _heading = reading.heading;
          _headingAccuracy = reading.accuracy;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _compassStarted = true;
          _heading = null;
          _headingAccuracy = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPoint = _currentPoint;
    final bearing = currentPoint == null
        ? 0.0
        : _compassService.bearingDegrees(currentPoint, _targetPoint);
    final distance = currentPoint == null
        ? null
        : _compassService.distanceMeters(currentPoint, _targetPoint);
    final arrived = distance != null && distance < _arrivalRadiusMeters;
    final hasHeading = _heading != null;
    // Only warn on a genuinely poor numeric accuracy. Many Android devices
    // report a null accuracy (unknown) even when the compass is fine — nagging
    // on that would show the calibration hint permanently.
    final needsCalibration =
        hasHeading &&
        _headingAccuracy != null &&
        _headingAccuracy!.abs() > _lowHeadingAccuracyDegrees;
    final turns = CompassService.rotationTurns(
      bearingDegrees: bearing,
      headingDegrees: _heading,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Arahkan ke UMKM',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(AppColors.textPrimary),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.umkm.namaUsaha,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            CompassArrow(turns: turns, arrived: arrived, size: 180),
            const SizedBox(height: 20),
            Text(
              arrived
                  ? 'Anda telah tiba'
                  : distance == null
                  ? 'Mengambil jarak...'
                  : _formatDistance(distance),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: arrived
                    ? const Color(AppColors.statusVerifiedText)
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentPoint == null
                  ? 'Menunggu lokasi Anda.'
                  : 'Arah ${bearing.toStringAsFixed(0)} derajat dari utara',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(AppColors.textMuted),
              ),
            ),
            if (_isLoadingLocation) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _Notice(
                icon: Icons.location_off_outlined,
                message: _errorMessage!,
                actionLabel: 'Coba Lagi',
                onPressed: _startLocation,
              ),
            ],
            if (!_compassStarted || !hasHeading) ...[
              const SizedBox(height: 16),
              const _Notice(
                icon: Icons.explore_off_outlined,
                message:
                    'Sensor kompas tidak tersedia. Panah memakai arah statis dari lokasi Anda.',
              ),
            ] else if (needsCalibration) ...[
              const SizedBox(height: 16),
              const _Notice(
                icon: Icons.screen_rotation_alt_outlined,
                message: 'Kalibrasi: gerakkan HP membentuk angka 8',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.round()} m';
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onPressed, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
