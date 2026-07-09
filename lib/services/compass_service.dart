import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class CompassReading {
  const CompassReading({required this.heading, required this.accuracy});

  final double? heading;
  final double? accuracy;
}

class CompassService {
  const CompassService();

  Stream<double?> heading() {
    return readings().map((reading) => reading.heading);
  }

  Stream<CompassReading> readings() {
    final events = FlutterCompass.events;
    if (events == null) return const Stream.empty();

    return events.map(
      (event) => CompassReading(
        heading: _normalizeDegrees(event.heading),
        accuracy: event.accuracy,
      ),
    );
  }

  double bearingDegrees(LatLng from, LatLng to) {
    final fromLat = _radians(from.latitude);
    final toLat = _radians(to.latitude);
    final dLon = _radians(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(toLat);
    final x =
        math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(dLon);

    return _normalizeDegrees(_degrees(math.atan2(y, x)))!;
  }

  double distanceMeters(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  static double rotationTurns({
    required double bearingDegrees,
    required double? headingDegrees,
  }) {
    final relativeDegrees = _normalizeDegrees(
      bearingDegrees - (headingDegrees ?? 0),
    )!;
    return relativeDegrees / 360;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  static double _degrees(double radians) => radians * 180 / math.pi;

  static double? _normalizeDegrees(double? degrees) {
    if (degrees == null || degrees.isNaN || degrees.isInfinite) return null;
    return (degrees % 360 + 360) % 360;
  }
}
