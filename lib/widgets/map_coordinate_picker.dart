import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/geocoding_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

typedef CurrentLocationLoader = Future<LatLng> Function();

class MapCoordinatePicker extends StatefulWidget {
  const MapCoordinatePicker({
    super.key,
    required this.onChanged,
    this.initialLatitude,
    this.initialLongitude,
    this.enabled = true,
    this.currentLocationLoader,
    this.geocodingService,
    this.errorText,
  });

  static const defaultCenter = LatLng(-8.409518, 115.188919);

  final ValueChanged<LatLng> onChanged;
  final double? initialLatitude;
  final double? initialLongitude;
  final bool enabled;
  final CurrentLocationLoader? currentLocationLoader;
  final GeocodingService? geocodingService;
  final String? errorText;

  @override
  State<MapCoordinatePicker> createState() => _MapCoordinatePickerState();
}

class _MapCoordinatePickerState extends State<MapCoordinatePicker> {
  static const _minimumSearchInterval = Duration(seconds: 1);

  final _addressController = TextEditingController();
  final _mapController = MapController();
  late GeocodingService _geocodingService;
  late LatLng _center;
  LatLng? _selectedPoint;
  List<GeocodeResult> _geocodeResults = const [];
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  bool _addressSearchCompleted = false;
  String? _locationErrorMessage;
  DateTime? _lastSearchStartedAt;

  @override
  void initState() {
    super.initState();
    _geocodingService = widget.geocodingService ?? GeocodingService();
    final initialPoint = _initialPoint;
    _center = initialPoint ?? MapCoordinatePicker.defaultCenter;
    _selectedPoint = initialPoint;
  }

  @override
  void didUpdateWidget(covariant MapCoordinatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.geocodingService != widget.geocodingService) {
      _geocodingService = widget.geocodingService ?? GeocodingService();
    }
    final initialChanged =
        oldWidget.initialLatitude != widget.initialLatitude ||
        oldWidget.initialLongitude != widget.initialLongitude;
    if (initialChanged) {
      final initialPoint = _initialPoint;
      if (initialPoint != null) {
        _center = initialPoint;
        _selectedPoint = initialPoint;
        _mapController.move(initialPoint, 15);
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  LatLng? get _initialPoint {
    final latitude = widget.initialLatitude;
    final longitude = widget.initialLongitude;
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final coordinateText = _selectedPoint == null
        ? 'Belum ada koordinat dipilih'
        : '${_selectedPoint!.latitude.toStringAsFixed(6)}, '
              '${_selectedPoint!.longitude.toStringAsFixed(6)}';
    final hasError = widget.errorText != null;
    final canUseCurrentLocation = widget.currentLocationLoader != null;
    final markerColor = Color(AppColors.markerPalette.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Koordinat Lokasi', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Ketuk atau geser peta untuk menandai lokasi UMKM.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _addressController,
                enabled: widget.enabled && !_isSearching,
                textInputAction: TextInputAction.search,
                onSubmitted: widget.enabled && !_isSearching
                    ? (_) => _searchAddress()
                    : null,
                decoration: InputDecoration(
                  labelText: 'Cari alamat lengkap',
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.primary,
                  shape: const StadiumBorder(),
                ),
                onPressed: widget.enabled && !_isSearching
                    ? _searchAddress
                    : null,
                icon: _isSearching
                    ? SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.search),
                label: const Text('Cari'),
              ),
            ),
          ],
        ),
        if (_geocodeResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _GeocodeResultList(
            results: _geocodeResults,
            enabled: widget.enabled,
            onSelected: _selectGeocodeResult,
          ),
        ] else if (_addressSearchCompleted && !_isSearching) ...[
          const SizedBox(height: 4),
          Text(
            'Alamat tidak ditemukan.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ],
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: hasError ? Border.all(color: colorScheme.error) : null,
            borderRadius: BorderRadius.circular(AppRadii.radiusCard),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.radiusCard),
            child: SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 15,
                      onTap: widget.enabled
                          ? (_, point) => _selectPoint(point, moveMap: true)
                          : null,
                      onPositionChanged: widget.enabled
                          ? (camera, hasGesture) {
                              if (hasGesture) {
                                _selectPoint(camera.center);
                              }
                            }
                          : null,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ppb2026.umkmap',
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 48,
                          color: Color(AppColors.surface),
                        ),
                        Icon(Icons.location_on, size: 44, color: markerColor),
                      ],
                    ),
                  ),
                  if (canUseCurrentLocation)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.primary,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: widget.enabled && !_isLoadingLocation
                            ? _useCurrentLocation
                            : null,
                        icon: _isLoadingLocation
                            ? SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Gunakan Lokasi Saya'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                coordinateText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasError ? colorScheme.error : null,
                ),
              ),
            ),
          ],
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
        if (_locationErrorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _locationErrorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
      ],
    );
  }

  void _selectPoint(LatLng point, {bool moveMap = false}) {
    setState(() {
      _selectedPoint = point;
      _locationErrorMessage = null;
    });
    if (moveMap) _mapController.move(point, _mapController.camera.zoom);
    widget.onChanged(point);
  }

  Future<void> _searchAddress() async {
    if (!widget.enabled || _isSearching) return;

    final query = _addressController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _geocodeResults = const [];
        _addressSearchCompleted = false;
        _locationErrorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _addressSearchCompleted = false;
      _geocodeResults = const [];
      _locationErrorMessage = null;
    });

    try {
      final lastSearchStartedAt = _lastSearchStartedAt;
      if (lastSearchStartedAt != null) {
        final elapsed = DateTime.now().difference(lastSearchStartedAt);
        if (elapsed < _minimumSearchInterval) {
          await Future<void>.delayed(_minimumSearchInterval - elapsed);
        }
      }

      _lastSearchStartedAt = DateTime.now();
      final results = await _geocodingService.search(query);
      if (!mounted) return;
      setState(() {
        _geocodeResults = results.take(5).toList(growable: false);
        _addressSearchCompleted = true;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _locationErrorMessage = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _locationErrorMessage = 'Gagal mencari alamat. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectGeocodeResult(GeocodeResult result) {
    setState(() {
      _geocodeResults = const [];
      _addressSearchCompleted = false;
    });
    _selectPoint(result.point, moveMap: true);
  }

  Future<void> _useCurrentLocation() async {
    final loader = widget.currentLocationLoader;
    if (loader == null) return;

    setState(() {
      _isLoadingLocation = true;
      _locationErrorMessage = null;
    });

    try {
      final point = await loader();
      if (!mounted) return;
      _selectPoint(point, moveMap: true);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _locationErrorMessage = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _locationErrorMessage = 'Gagal mengambil lokasi saat ini.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }
}

class _GeocodeResultList extends StatelessWidget {
  const _GeocodeResultList({
    required this.results,
    required this.enabled,
    required this.onSelected,
  });

  final List<GeocodeResult> results;
  final bool enabled;
  final ValueChanged<GeocodeResult> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: results.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: Color(AppColors.hairline)),
          itemBuilder: (context, index) {
            return ListTile(
              dense: true,
              enabled: enabled,
              leading: Icon(
                Icons.place_outlined,
                color: colorScheme.primary,
                size: 16,
              ),
              title: Text(
                results[index].displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: enabled ? () => onSelected(results[index]) : null,
            );
          },
        ),
      ),
    );
  }
}
