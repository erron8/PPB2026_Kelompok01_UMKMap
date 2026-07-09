import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:umkmap/services/compass_service.dart';
import 'package:umkmap/widgets/compass_arrow.dart';

void main() {
  test('bearingDegrees returns north/east/south/west bearings', () {
    const service = CompassService();
    const origin = LatLng(0, 0);

    expect(service.bearingDegrees(origin, const LatLng(1, 0)), closeTo(0, .01));
    expect(
      service.bearingDegrees(origin, const LatLng(0, 1)),
      closeTo(90, .01),
    );
    expect(
      service.bearingDegrees(origin, const LatLng(-1, 0)),
      closeTo(180, .01),
    );
    expect(
      service.bearingDegrees(origin, const LatLng(0, -1)),
      closeTo(270, .01),
    );
  });

  test('distanceMeters uses meter scale and is symmetric', () {
    const service = CompassService();
    const from = LatLng(-8.6500, 115.2167);
    const to = LatLng(-8.6510, 115.2167);

    final distance = service.distanceMeters(from, to);
    final reversed = service.distanceMeters(to, from);

    expect(distance, closeTo(111, 2));
    expect(reversed, closeTo(distance, .001));
  });

  test('rotationTurns subtracts device heading from target bearing', () {
    expect(
      CompassService.rotationTurns(bearingDegrees: 90, headingDegrees: 45),
      closeTo(.125, .001),
    );
    expect(
      CompassService.rotationTurns(bearingDegrees: 10, headingDegrees: 350),
      closeTo(20 / 360, .001),
    );
    expect(
      CompassService.rotationTurns(bearingDegrees: 270, headingDegrees: null),
      closeTo(.75, .001),
    );
  });

  testWidgets('CompassArrow applies animated rotation turns', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CompassArrow(turns: .25))),
    );

    final rotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(rotation.turns, .25);
  });

  testWidgets('CompassArrow rotates the short way across the 0/1 boundary', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CompassArrow(turns: .97))),
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CompassArrow(turns: .02))),
    );

    final rotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    // .97 -> .02 is a +.05 turn the short way, so the cumulative value should
    // step forward to ~1.02, never back down to .02 (which would spin ~350°).
    expect(rotation.turns, closeTo(1.02, .0001));
  });
}
