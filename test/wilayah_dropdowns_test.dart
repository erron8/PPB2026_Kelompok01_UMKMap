import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umkmap/models/wilayah.dart';
import 'package:umkmap/services/wilayah_api_service.dart';
import 'package:umkmap/widgets/wilayah_dropdowns.dart';

void main() {
  testWidgets('cascades selections and resets children when province changes', (
    tester,
  ) async {
    final service = _FakeWilayahApiService();
    final selections = <_Selection>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: WilayahDropdowns(
              service: service,
              onChanged: ({province, regency, district}) {
                selections.add(
                  _Selection(
                    provinceId: province?.id,
                    regencyId: regency?.id,
                    districtId: district?.id,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _chooseDropdown(
      tester,
      const ValueKey('wilayah_province_dropdown'),
      'SULAWESI SELATAN',
    );
    expect(selections.last, const _Selection(provinceId: '73'));

    await _chooseDropdown(
      tester,
      const ValueKey('wilayah_regency_dropdown'),
      'KOTA MAKASSAR',
    );
    expect(
      selections.last,
      const _Selection(provinceId: '73', regencyId: '7371'),
    );

    await _chooseDropdown(
      tester,
      const ValueKey('wilayah_district_dropdown'),
      'PANAKKUKANG',
    );
    expect(
      selections.last,
      const _Selection(
        provinceId: '73',
        regencyId: '7371',
        districtId: '7371100',
      ),
    );

    await _chooseDropdown(
      tester,
      const ValueKey('wilayah_province_dropdown'),
      'BALI',
    );

    expect(selections.last, const _Selection(provinceId: '51'));
    expect(find.text('Pilih kota/kabupaten'), findsOneWidget);
    expect(find.text('Pilih kecamatan'), findsNothing);
    expect(find.text('Pilih kota/kabupaten dahulu'), findsOneWidget);
  });
}

Future<void> _chooseDropdown(
  WidgetTester tester,
  ValueKey<String> key,
  String label,
) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _FakeWilayahApiService extends WilayahApiService {
  @override
  Future<List<Wilayah>> provinces() async {
    return const [
      Wilayah(id: '73', name: 'SULAWESI SELATAN'),
      Wilayah(id: '51', name: 'BALI'),
    ];
  }

  @override
  Future<List<Wilayah>> regencies(String provinceId) async {
    return switch (provinceId) {
      '73' => const [Wilayah(id: '7371', name: 'KOTA MAKASSAR')],
      '51' => const [Wilayah(id: '5171', name: 'KOTA DENPASAR')],
      _ => const [],
    };
  }

  @override
  Future<List<Wilayah>> districts(String regencyId) async {
    return switch (regencyId) {
      '7371' => const [Wilayah(id: '7371100', name: 'PANAKKUKANG')],
      '5171' => const [Wilayah(id: '5171010', name: 'DENPASAR SELATAN')],
      _ => const [],
    };
  }
}

class _Selection {
  const _Selection({this.provinceId, this.regencyId, this.districtId});

  final String? provinceId;
  final String? regencyId;
  final String? districtId;

  @override
  bool operator ==(Object other) {
    return other is _Selection &&
        provinceId == other.provinceId &&
        regencyId == other.regencyId &&
        districtId == other.districtId;
  }

  @override
  int get hashCode => Object.hash(provinceId, regencyId, districtId);

  @override
  String toString() {
    return 'Selection(provinceId: $provinceId, regencyId: $regencyId, '
        'districtId: $districtId)';
  }
}
