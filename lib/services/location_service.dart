import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../utils/app_exception.dart';

enum LocationAvailability { ready, serviceDisabled, denied, deniedForever }

class LocationService {
  const LocationService();

  Future<LocationAvailability> ensurePermissionAndService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationAvailability.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAvailability.ready,
      LocationPermission.denied => LocationAvailability.denied,
      LocationPermission.deniedForever => LocationAvailability.deniedForever,
      LocationPermission.unableToDetermine => LocationAvailability.denied,
    };
  }

  Future<LatLng> current() async {
    await _throwIfUnavailable();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return _toLatLng(position);
  }

  Stream<LatLng> stream() async* {
    await _throwIfUnavailable();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map(_toLatLng);
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> _throwIfUnavailable() async {
    final availability = await ensurePermissionAndService();
    if (availability == LocationAvailability.ready) return;
    throw AppException(messageFor(availability));
  }

  static String messageFor(LocationAvailability availability) {
    return switch (availability) {
      LocationAvailability.ready => '',
      LocationAvailability.serviceDisabled =>
        'GPS tidak aktif. Aktifkan layanan lokasi untuk menampilkan posisi Anda.',
      LocationAvailability.denied =>
        'Izin lokasi ditolak. Berikan izin lokasi untuk menampilkan posisi Anda.',
      LocationAvailability.deniedForever =>
        'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
    };
  }

  static LatLng _toLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }
}
