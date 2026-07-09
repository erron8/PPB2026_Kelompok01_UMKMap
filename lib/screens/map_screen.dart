import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/kategori.dart';
import '../models/umkm.dart';
import '../providers/location_provider.dart';
import '../providers/umkm_provider.dart';
import '../services/location_service.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';
import '../widgets/map_coordinate_picker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  bool _initialized = false;
  bool _hasAutoCentered = false;
  bool _tileErrorVisible = false;
  int _tileRetryKey = 0;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (_initialized) return;
    _initialized = true;

    await Future.wait([
      context.read<UmkmProvider>().loadCategories(),
      context.read<UmkmProvider>().loadMapItems(),
      context.read<LocationProvider>().startStream(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final umkmProvider = context.watch<UmkmProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final allItems = umkmProvider.mapItems;
    final visibleItems = _selectedCategoryId == null
        ? allItems
        : allItems
              .where((umkm) => umkm.kategoriId == _selectedCategoryId)
              .toList(growable: false);
    final currentLocation = locationProvider.currentLocation;
    final initialCenter =
        currentLocation ??
        (allItems.isEmpty
            ? MapCoordinatePicker.defaultCenter
            : LatLng(allItems.first.latitude, allItems.first.longitude));

    _autoCenterOnce(currentLocation, allItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta UMKM'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang peta',
            onPressed: () {
              setState(() => _tileErrorVisible = false);
              context.read<UmkmProvider>().loadMapItems();
              _refreshLocation();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: initialCenter, initialZoom: 12),
            children: [
              TileLayer(
                key: ValueKey(_tileRetryKey),
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  ...visibleItems.map(
                    (umkm) => Marker(
                      point: LatLng(umkm.latitude, umkm.longitude),
                      width: 140,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: _UmkmMarker(
                        label: umkm.namaUsaha,
                        color: _categoryColor(context, umkm.kategoriId),
                        onTap: () => _showUmkmSheet(context, umkm),
                      ),
                    ),
                  ),
                  if (currentLocation != null)
                    Marker(
                      point: currentLocation,
                      width: 34,
                      height: 34,
                      child: _UserLocationDot(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (umkmProvider.isLoadingMapItems && allItems.isEmpty)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: _MapBanners(
              tileErrorVisible: _tileErrorVisible,
              umkmErrorMessage: umkmProvider.mapErrorMessage,
              locationProvider: locationProvider,
              onRetryTiles: () {
                setState(() {
                  _tileRetryKey++;
                  _tileErrorVisible = false;
                });
              },
              onRetryUmkm: umkmProvider.loadMapItems,
              onRetryLocation: _refreshLocation,
            ),
          ),
          if (!umkmProvider.isLoadingMapItems && visibleItems.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: _EmptyMapMessage(
                    message: _selectedCategoryId == null
                        ? umkmProvider.mapErrorMessage ??
                              'Belum ada UMKM terverifikasi di peta.'
                        : 'Belum ada UMKM kategori ini di peta.',
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 82,
            bottom: 16,
            child: _CategoryLegend(
              categories: umkmProvider.categories,
              selectedId: _selectedCategoryId,
              colorFor: (id) => _categoryColor(context, id),
              onToggle: (id) {
                setState(() {
                  _selectedCategoryId = _selectedCategoryId == id ? null : id;
                });
              },
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              tooltip: 'Lokasi saya',
              onPressed: locationProvider.isLoading ? null : _moveToMyLocation,
              child: locationProvider.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  void _autoCenterOnce(LatLng? currentLocation, List<Umkm> markers) {
    if (_hasAutoCentered) return;
    final point =
        currentLocation ??
        (markers.isEmpty
            ? null
            : LatLng(markers.first.latitude, markers.first.longitude));
    if (point == null) return;

    _hasAutoCentered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(point, currentLocation == null ? 12 : 15);
    });
  }

  Future<void> _moveToMyLocation() async {
    final locationProvider = context.read<LocationProvider>();
    try {
      final point = await locationProvider.loadCurrentPoint();
      if (!mounted) return;
      _mapController.move(point, 16);
    } catch (_) {
      if (!mounted) return;
      final message =
          locationProvider.errorMessage ?? 'Gagal mengambil lokasi saat ini.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _refreshLocation() async {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.isStreaming) {
      await locationProvider.refreshCurrent();
      return;
    }
    await locationProvider.startStream();
  }

  void _showUmkmSheet(BuildContext context, Umkm umkm) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _UmkmMapSheet(umkm: umkm),
    );
  }

  Color _categoryColor(BuildContext context, int kategoriId) {
    final colors = AppColors.markerPalette;
    return Color(colors[(kategoriId - 1).abs() % colors.length]);
  }
}

class _UmkmMarker extends StatelessWidget {
  const _UmkmMarker({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 132),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Icon(Icons.location_on, size: 36, color: color),
        ],
      ),
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}

class _MapBanners extends StatelessWidget {
  const _MapBanners({
    required this.tileErrorVisible,
    required this.umkmErrorMessage,
    required this.locationProvider,
    required this.onRetryTiles,
    required this.onRetryUmkm,
    required this.onRetryLocation,
  });

  final bool tileErrorVisible;
  final String? umkmErrorMessage;
  final LocationProvider locationProvider;
  final VoidCallback onRetryTiles;
  final VoidCallback onRetryUmkm;
  final VoidCallback onRetryLocation;

  @override
  Widget build(BuildContext context) {
    final banners = <Widget>[];
    final locationError = locationProvider.errorMessage;

    if (tileErrorVisible) {
      banners.add(
        _MapBanner(
          icon: Icons.wifi_off,
          message: 'Tidak ada koneksi internet',
          actionLabel: 'Coba Lagi',
          onAction: onRetryTiles,
        ),
      );
    }
    if (umkmErrorMessage != null) {
      banners.add(
        _MapBanner(
          icon: Icons.storefront_outlined,
          message: umkmErrorMessage!,
          actionLabel: 'Coba Lagi',
          onAction: onRetryUmkm,
        ),
      );
    }
    if (locationError != null) {
      banners.add(
        _MapBanner(
          icon: Icons.location_off_outlined,
          message: locationError,
          actionLabel: _locationActionLabel(locationProvider.availability),
          onAction: () => _handleLocationAction(context),
        ),
      );
    }

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final banner in banners) ...[banner, const SizedBox(height: 8)],
      ],
    );
  }

  String _locationActionLabel(LocationAvailability? availability) {
    return switch (availability) {
      LocationAvailability.serviceDisabled => 'Aktifkan',
      LocationAvailability.deniedForever => 'Pengaturan',
      _ => 'Coba Lagi',
    };
  }

  Future<void> _handleLocationAction(BuildContext context) async {
    final availability = locationProvider.availability;
    if (availability == LocationAvailability.serviceDisabled) {
      await locationProvider.openLocationSettings();
      return;
    }
    if (availability == LocationAvailability.deniedForever) {
      await locationProvider.openAppSettings();
      return;
    }
    onRetryLocation();
  }
}

class _MapBanner extends StatelessWidget {
  const _MapBanner({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyMapMessage extends StatelessWidget {
  const _EmptyMapMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.categories,
    required this.selectedId,
    required this.colorFor,
    required this.onToggle,
  });

  final List<Kategori> categories;
  final int? selectedId;
  final Color Function(int id) colorFor;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _LegendChip(
                  label: category.nama,
                  color: colorFor(category.id),
                  selected: selectedId == category.id,
                  onTap: () => onToggle(category.id),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = selected ? Colors.white : null;

    return Material(
      color: selected ? color : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: selected ? 2 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: selected ? Colors.white : color,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UmkmMapSheet extends StatelessWidget {
  const _UmkmMapSheet({required this.umkm});

  final Umkm umkm;

  @override
  Widget build(BuildContext context) {
    final photoUrl = umkm.fotoUrl;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: 76,
                child: photoUrl == null || photoUrl.isEmpty
                    ? ColoredBox(
                        color: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.storefront,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => ColoredBox(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    umkm.namaUsaha,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    umkm.kategoriNama ?? 'Kategori ${umkm.kategoriId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.address(umkm),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.push('/umkm/${umkm.id}');
                      },
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Detail'),
                    ),
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
