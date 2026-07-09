import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:umkmap/services/wilayah_api_service.dart';

void main() {
  test(
    'regencies uses the network response and caches by province id',
    () async {
      var calls = 0;
      final service = WilayahApiService(
        client: MockClient((request) async {
          calls += 1;
          expect(request.url.path, endsWith('/regencies/73.json'));
          return http.Response('[{"id":"7371","name":"KOTA MAKASSAR"}]', 200);
        }),
        assetBundle: _StringAssetBundle(const {}),
      );

      final first = await service.regencies('73');
      final second = await service.regencies('73');

      expect(first.single.id, '7371');
      expect(second.single.name, 'KOTA MAKASSAR');
      expect(calls, 1);
    },
  );

  test('provinces falls back to bundled JSON when the network fails', () async {
    final service = WilayahApiService(
      client: MockClient((request) async => throw Exception('offline')),
      assetBundle: _StringAssetBundle(const {
        'assets/wilayah/provinces.json':
            '[{"id":"73","name":"SULAWESI SELATAN"}]',
      }),
    );

    final provinces = await service.provinces();

    expect(provinces, hasLength(1));
    expect(provinces.single.id, '73');
    expect(provinces.single.name, 'SULAWESI SELATAN');
  });
}

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw StateError('Missing test asset: $key');
    }

    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }
}
