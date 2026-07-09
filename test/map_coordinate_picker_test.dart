import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:umkmap/services/geocoding_service.dart';
import 'package:umkmap/widgets/map_coordinate_picker.dart';

void main() {
  testWidgets('selecting an address search result updates the coordinate', (
    tester,
  ) async {
    LatLng? selectedPoint;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapCoordinatePicker(
            geocodingService: _FakeGeocodingService(const [
              GeocodeResult(
                displayName: 'Jalan Sudirman, Denpasar',
                point: LatLng(-8.670458, 115.212631),
              ),
            ]),
            onChanged: (point) => selectedPoint = point,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Jl. Sudirman Denpasar');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cari'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jalan Sudirman, Denpasar'));
    await tester.pumpAndSettle();

    expect(selectedPoint, isNotNull);
    expect(selectedPoint!.latitude, closeTo(-8.670458, 0.000001));
    expect(selectedPoint!.longitude, closeTo(115.212631, 0.000001));
  });
}

class _FakeGeocodingService extends GeocodingService {
  _FakeGeocodingService(this.results);

  final List<GeocodeResult> results;

  @override
  Future<List<GeocodeResult>> search(String query) async => results;
}
