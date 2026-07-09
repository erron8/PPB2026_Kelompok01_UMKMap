import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../utils/app_exception.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider({LocationService service = const LocationService()})
    : _service = service;

  final LocationService _service;
  StreamSubscription<LatLng>? _subscription;

  LatLng? currentLocation;
  LocationAvailability? availability;
  bool isLoading = false;
  bool isStreaming = false;
  String? errorMessage;

  Future<void> refreshCurrent() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      availability = await _service.ensurePermissionAndService();
      if (availability != LocationAvailability.ready) {
        currentLocation = null;
        errorMessage = LocationService.messageFor(availability!);
        return;
      }

      currentLocation = await _service.current();
      errorMessage = null;
    } on AppException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Gagal mengambil lokasi saat ini.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startStream() async {
    if (_subscription != null) return;

    await refreshCurrent();
    if (availability != LocationAvailability.ready) return;

    isStreaming = true;
    notifyListeners();

    _subscription = _service.stream().listen(
      (point) {
        currentLocation = point;
        errorMessage = null;
        notifyListeners();
      },
      onError: (_) async {
        await _subscription?.cancel();
        _subscription = null;
        isStreaming = false;
        // Re-evaluate why the stream dropped (e.g. GPS switched off) so the
        // banner shows the correct cause and action (Aktifkan / Pengaturan).
        availability = await _service.ensurePermissionAndService();
        errorMessage = availability == LocationAvailability.ready
            ? 'Gagal memperbarui lokasi langsung.'
            : LocationService.messageFor(availability!);
        notifyListeners();
      },
    );
  }

  Future<LatLng> loadCurrentPoint() async {
    availability = await _service.ensurePermissionAndService();
    if (availability != LocationAvailability.ready) {
      final message = LocationService.messageFor(availability!);
      errorMessage = message;
      notifyListeners();
      throw AppException(message);
    }

    try {
      final point = await _service.current();
      currentLocation = point;
      errorMessage = null;
      notifyListeners();
      return point;
    } on AppException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (_) {
      const error = AppException('Gagal mengambil lokasi saat ini.');
      errorMessage = error.message;
      notifyListeners();
      throw error;
    }
  }

  Future<void> openLocationSettings() => _service.openLocationSettings();

  Future<void> openAppSettings() => _service.openAppSettings();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
