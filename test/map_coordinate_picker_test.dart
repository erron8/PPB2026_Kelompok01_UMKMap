import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:umkmap/services/geocoding_service.dart';
import 'package:umkmap/widgets/map_coordinate_picker.dart';

void main() {
  // The real form renders the picker inside a scrolling ListView; this catches
  // regressions where the address-search button receives infinite width.
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: ListView(children: [child])),
  );

  testWidgets('renders inside a ListView without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MapCoordinatePicker(
          geocodingService: _FakeGeocodingService(const []),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Cari'), findsOneWidget);
  });

  testWidgets('selecting an address search result updates the coordinate', (
    tester,
  ) async {
    LatLng? selectedPoint;

    await tester.pumpWidget(
      wrap(
        MapCoordinatePicker(
          geocodingService: _FakeGeocodingService(const [
            GeocodeResult(
              displayName: 'Jalan Sudirman, Denpasar',
              point: LatLng(-8.670458, 115.212631),
            ),
          ]),
          onChanged: (point) => selectedPoint = point,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Jl. Sudirman Denpasar');
    await tester.tap(find.widgetWithText(FilledButton, 'Cari'));
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
