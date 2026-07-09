import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

typedef CurrentLocationLoader = Future<LatLng> Function();

class MapCoordinatePicker extends StatefulWidget {
  const MapCoordinatePicker({
    super.key,
    required this.onChanged,
    this.initialLatitude,
    this.initialLongitude,
    this.enabled = true,
    this.currentLocationLoader,
    this.errorText,
  });

  static const defaultCenter = LatLng(-5.147665, 119.432732);

  final ValueChanged<LatLng> onChanged;
  final double? initialLatitude;
  final double? initialLongitude;
  final bool enabled;
  final CurrentLocationLoader? currentLocationLoader;
  final String? errorText;

  @override
  State<MapCoordinatePicker> createState() => _MapCoordinatePickerState();
}

class _MapCoordinatePickerState extends State<MapCoordinatePicker> {
  final _mapController = MapController();
  late LatLng _center;
  LatLng? _selectedPoint;
  bool _isLoadingLocation = false;
  String? _locationErrorMessage;

  @override
  void initState() {
    super.initState();
    final initialPoint = _initialPoint;
    _center = initialPoint ?? MapCoordinatePicker.defaultCenter;
    _selectedPoint = initialPoint;
  }

  @override
  void didUpdateWidget(covariant MapCoordinatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Koordinat Lokasi', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? colorScheme.error : colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
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
                    child: Icon(
                      Icons.location_on,
                      size: 44,
                      color: colorScheme.secondary,
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
            if (canUseCurrentLocation) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.enabled && !_isLoadingLocation
                    ? _useCurrentLocation
                    : null,
                icon: _isLoadingLocation
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Lokasi Saya'),
              ),
            ],
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
