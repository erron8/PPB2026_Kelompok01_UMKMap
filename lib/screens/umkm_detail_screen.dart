import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:image_picker/image_picker.dart';

import '../models/umkm.dart';
import '../providers/auth_provider.dart';
import '../providers/umkm_provider.dart';
import '../services/compass_service.dart';
import '../services/location_service.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';
import '../widgets/compass_arrow.dart';
import '../widgets/loading_and_error.dart';
import '../widgets/photo_picker_field.dart';
import '../widgets/primary_button.dart';
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
    final user = auth.user;
    final isOwner = user?.id == umkm.ownerId;
    final canEdit = auth.isAdmin || isOwner;
    final isGoldOrAbove = user != null && (
      user.tier == 'Gold' ||
      user.tier == 'Platinum' ||
      user.tier == 'Super User'
    );
    final canVerify = auth.isAdmin || (isGoldOrAbove && !isOwner);
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
                      reporterId: user?.id,
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
                        if (umkm.hariOperasional != null &&
                            umkm.hariOperasional!.trim().isNotEmpty)
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Hari Operasional',
                            value: umkm.hariOperasional!,
                          ),
                        if (umkm.jamOperasional != null &&
                            umkm.jamOperasional!.trim().isNotEmpty)
                          _InfoRow(
                            icon: Icons.access_time,
                            label: 'Jam Operasional',
                            value: umkm.jamOperasional!,
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
                    _CategoryDetailsSection(umkm: umkm),
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
    this.reporterId,
  });

  final Umkm umkm;
  final bool canEdit;
  final bool canVerify;
  final String? reporterId;

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
            label: const Text('Setujui'),
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
        if (reporterId != null && reporterId != umkm.ownerId)
          OutlinedButton.icon(
            style: destructiveStyle,
            onPressed: isBusy ? null : () => _showReportSheet(context, reporterId!),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Laporkan'),
          ),
      ],
    );
  }

  Future<void> _showReportSheet(BuildContext context, String reporterId) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ReportFormSheet(umkm: umkm, reporterId: reporterId),
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

class _CategoryDetailsSection extends StatelessWidget {
  const _CategoryDetailsSection({required this.umkm});

  final Umkm umkm;

  String _formatRupiah(int amount) {
    final cleanAmount = amount.toString();
    final parts = [];
    int i = cleanAmount.length;
    while (i > 3) {
      parts.add(cleanAmount.substring(i - 3, i));
      i -= 3;
    }
    if (i > 0) {
      parts.add(cleanAmount.substring(0, i));
    }
    return 'Rp ${parts.reversed.join('.')}';
  }

  @override
  Widget build(BuildContext context) {
    final detail = umkm.detailKategori;
    if (detail == null) return const SizedBox.shrink();

    final items = detail['items'] as List?;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    final catName = (umkm.kategoriNama ?? '').toLowerCase();

    String sectionTitle = 'Detail Spesifik';
    if (catName == 'kuliner') {
      sectionTitle = 'Menu Andalan';
    } else if (catName == 'jasa') {
      sectionTitle = 'Layanan Jasa';
    } else if (catName == 'fashion') {
      sectionTitle = 'Katalog Produk Fashion';
    } else if (catName == 'kerajinan') {
      sectionTitle = 'Katalog Kerajinan';
    } else if (catName == 'pertanian') {
      sectionTitle = 'Hasil Pertanian & Panen';
    } else if (catName == 'lainnya') {
      sectionTitle = 'Informasi Tambahan';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _SectionTitle(title: sectionTitle),
        const SizedBox(height: 8),
        _DetailsCard(
          children: [
            if (catName == 'kuliner')
              ...items.map((it) {
                final map = it as Map;
                final nama = map['nama'] as String? ?? '-';
                final harga = map['harga'] as int? ?? 0;
                final fotoUrl = map['foto_url'] as String?;
                return _ItemTileWithPhoto(
                  title: nama,
                  subtitle: _formatRupiah(harga),
                  photoUrl: fotoUrl,
                  fallbackIcon: Icons.restaurant_menu,
                );
              })
            else if (catName == 'jasa')
              ...items.map((it) {
                final map = it as Map;
                final nama = map['nama'] as String? ?? '-';
                final hargaMulai = map['harga_mulai'] as int? ?? 0;
                final deskripsi = map['deskripsi'] as String? ?? '';
                return _ItemTileWithIcon(
                  title: nama,
                  subtitle: 'Mulai dari ${_formatRupiah(hargaMulai)}',
                  description: deskripsi.isNotEmpty ? deskripsi : null,
                  icon: Icons.design_services_outlined,
                );
              })
            else if (catName == 'fashion')
              ...items.map((it) {
                final map = it as Map;
                final nama = map['nama'] as String? ?? '-';
                final harga = map['harga'] as int? ?? 0;
                final ukuran = List<String>.from(map['ukuran'] as List? ?? []);
                final fotoUrl = map['foto_url'] as String?;
                return _ItemTileWithPhoto(
                  title: nama,
                  subtitle: _formatRupiah(harga),
                  photoUrl: fotoUrl,
                  extra: ukuran.isNotEmpty ? 'Ukuran: ${ukuran.join(', ')}' : null,
                  fallbackIcon: Icons.checkroom_outlined,
                );
              })
            else if (catName == 'kerajinan')
              ...items.map((it) {
                final map = it as Map;
                final nama = map['nama'] as String? ?? '-';
                final harga = map['harga'] as int? ?? 0;
                final bahan = map['bahan'] as String? ?? '-';
                final fotoUrl = map['foto_url'] as String?;
                return _ItemTileWithPhoto(
                  title: nama,
                  subtitle: _formatRupiah(harga),
                  photoUrl: fotoUrl,
                  extra: 'Bahan: $bahan',
                  fallbackIcon: Icons.brush_outlined,
                );
              })
            else if (catName == 'pertanian')
              ...items.map((it) {
                final map = it as Map;
                final nama = map['nama'] as String? ?? '-';
                final harga = map['harga'] as int? ?? 0;
                final panen = map['panen'] as String? ?? '';
                final deskripsi = map['deskripsi'] as String? ?? '';
                return _ItemTileWithIcon(
                  title: nama,
                  subtitle: '${_formatRupiah(harga)} / satuan',
                  description: [
                    if (panen.isNotEmpty) 'Musim Panen: $panen',
                    if (deskripsi.isNotEmpty) deskripsi,
                  ].join('\n'),
                  icon: Icons.agriculture_outlined,
                );
              })
            else
              ...items.map((it) {
                final map = it as Map;
                final key = map['key'] as String? ?? '';
                final value = map['value'] as String? ?? '';
                return _ItemTileWithIcon(
                  title: key,
                  subtitle: value,
                  icon: Icons.info_outline,
                );
              }),
          ],
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class _ItemTileWithPhoto extends StatelessWidget {
  const _ItemTileWithPhoto({
    required this.title,
    required this.subtitle,
    this.photoUrl,
    this.extra,
    required this.fallbackIcon,
  });

  final String title;
  final String subtitle;
  final String? photoUrl;
  final String? extra;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(AppColors.primaryContainer),
              borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Icon(fallbackIcon, color: const Color(AppColors.primary), size: 24)
                  : CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, _, error) => Icon(fallbackIcon, color: const Color(AppColors.primary), size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(AppColors.textPrimary),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(AppColors.primary),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (extra != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    extra!,
                    style: const TextStyle(
                      color: Color(AppColors.textSubtle),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTileWithIcon extends StatelessWidget {
  const _ItemTileWithIcon({
    required this.title,
    required this.subtitle,
    this.description,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String? description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(AppColors.primaryContainer),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(AppColors.primary), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(AppColors.textPrimary),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(AppColors.primary),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: const TextStyle(
                      color: Color(AppColors.textSubtle),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportFormSheet extends StatefulWidget {
  const _ReportFormSheet({
    required this.umkm,
    required this.reporterId,
  });

  final Umkm umkm;
  final String reporterId;

  @override
  State<_ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends State<_ReportFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _tipeLaporan = 'Tutup Permanen';
  XFile? _selectedPhoto;
  String? _photoErrorText;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    
    setState(() {
      if (_selectedPhoto == null) {
        _photoErrorText = 'Foto bukti wajib disertakan.';
      } else {
        _photoErrorText = null;
      }
    });

    if (!formValid || _selectedPhoto == null) return;

    final provider = context.read<UmkmProvider>();
    final success = await provider.submitReport(
      umkmId: widget.umkm.id,
      reporterId: widget.reporterId,
      tipeLaporan: _tipeLaporan,
      deskripsi: _descriptionController.text.trim(),
      fotoBukti: _selectedPhoto!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan Anda berhasil dikirim dan akan diverifikasi.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.reportMutationErrorMessage ?? 'Gagal mengirim laporan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitting = context.watch<UmkmProvider>().isSubmittingReport;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Laporkan Masalah',
                textAlign: TextAlign.center,
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
              DropdownButtonFormField<String>(
                initialValue: _tipeLaporan,
                decoration: const InputDecoration(labelText: 'Tipe Masalah'),
                items: const [
                  DropdownMenuItem(value: 'Tutup Permanen', child: Text('Tutup Permanen')),
                  DropdownMenuItem(value: 'Pindah Lokasi', child: Text('Pindah Lokasi')),
                  DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _tipeLaporan = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi / Alasan',
                  hintText: 'Tulis kronologi atau alasan laporan secara detail',
                ),
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Deskripsi wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Foto Bukti Konkrit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              PhotoPickerField(
                selectedFile: _selectedPhoto,
                enabled: !isSubmitting,
                onChanged: (file) {
                  setState(() {
                    _selectedPhoto = file;
                    if (file != null) _photoErrorText = null;
                  });
                },
                onRemoved: () {
                  setState(() {
                    _selectedPhoto = null;
                  });
                },
              ),
              if (_photoErrorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  _photoErrorText!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: isSubmitting ? null : _submit,
                isLoading: isSubmitting,
                label: 'Kirim Laporan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
