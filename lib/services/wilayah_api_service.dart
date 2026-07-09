import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/wilayah.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

class WilayahApiService {
  WilayahApiService({
    http.Client? client,
    AssetBundle? assetBundle,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _assetBundle = assetBundle ?? rootBundle,
       _timeout = timeout;

  static const _assetDirectory = 'assets/wilayah';

  final http.Client _client;
  final AssetBundle _assetBundle;
  final Duration _timeout;
  final Map<String, List<Wilayah>> _cache = {};

  Future<List<Wilayah>> provinces() {
    return _fetch(
      cacheKey: 'provinces',
      url: '${AppConfig.wilayahBaseUrl}/provinces.json',
      assetPath: '$_assetDirectory/provinces.json',
    );
  }

  Future<List<Wilayah>> regencies(String provinceId) {
    return _fetch(
      cacheKey: 'regencies_$provinceId',
      url: '${AppConfig.wilayahBaseUrl}/regencies/$provinceId.json',
      assetPath: '$_assetDirectory/regencies_$provinceId.json',
    );
  }

  Future<List<Wilayah>> districts(String regencyId) {
    return _fetch(
      cacheKey: 'districts_$regencyId',
      url: '${AppConfig.wilayahBaseUrl}/districts/$regencyId.json',
      assetPath: '$_assetDirectory/districts_$regencyId.json',
    );
  }

  Future<List<Wilayah>> _fetch({
    required String cacheKey,
    required String url,
    required String assetPath,
  }) async {
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      final response = await _client.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException('HTTP ${response.statusCode}');
      }

      final wilayah = _decodeList(response.body);
      _cache[cacheKey] = wilayah;
      return wilayah;
    } on Object catch (error) {
      final fallback = await _loadFallback(assetPath);
      if (fallback != null) {
        _cache[cacheKey] = fallback;
        return fallback;
      }

      throw AppException.fromObject(
        error,
        fallback: 'Gagal memuat data wilayah. Coba lagi.',
      );
    }
  }

  Future<List<Wilayah>?> _loadFallback(String assetPath) async {
    try {
      final json = await _assetBundle.loadString(assetPath);
      return _decodeList(json);
    } on Object {
      return null;
    }
  }

  List<Wilayah> _decodeList(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const AppException('Format data wilayah tidak valid.');
    }

    return decoded
        .cast<Map<String, dynamic>>()
        .map(Wilayah.fromJson)
        .toList(growable: false);
  }
}
