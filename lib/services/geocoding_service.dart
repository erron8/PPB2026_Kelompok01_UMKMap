import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../utils/app_exception.dart';
import '../utils/constants.dart';

class GeocodeResult {
  const GeocodeResult({required this.displayName, required this.point});

  final String displayName;
  final LatLng point;
}

class GeocodingService {
  GeocodingService({
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  Future<List<GeocodeResult>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    try {
      final uri = Uri.parse('${AppConfig.nominatimBaseUrl}/search').replace(
        queryParameters: {
          'q': trimmedQuery,
          'format': 'jsonv2',
          'limit': '5',
          'countrycodes': 'id',
          'addressdetails': '1',
        },
      );
      final response = await _client
          .get(uri, headers: const {'User-Agent': 'com.ppb2026.umkmap'})
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException('HTTP ${response.statusCode}');
      }

      return _decodeList(response.body);
    } on Object catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal mencari alamat. Coba lagi.',
      );
    }
  }

  List<GeocodeResult> _decodeList(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const AppException('Format data alamat tidak valid.');
    }

    return decoded
        .map((item) {
          if (item is! Map) {
            throw const AppException('Format data alamat tidak valid.');
          }

          final json = Map<String, dynamic>.from(item);
          final displayName = json['display_name'];
          final latitude = json['lat'];
          final longitude = json['lon'];
          if (displayName is! String ||
              latitude is! String ||
              longitude is! String) {
            throw const AppException('Format data alamat tidak valid.');
          }

          return GeocodeResult(
            displayName: displayName,
            point: LatLng(double.parse(latitude), double.parse(longitude)),
          );
        })
        .toList(growable: false);
  }
}
