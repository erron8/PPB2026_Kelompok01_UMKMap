import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_client.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

class StorageService {
  StorageService({SupabaseClient? client})
    : _client = client ?? AppSupabase.client;

  static const int _maxPhotoBytes = 300 * 1024;

  final SupabaseClient _client;

  Future<String> uploadPhoto({
    required XFile file,
    required String umkmId,
  }) async {
    final cleanUmkmId = umkmId.trim();
    if (cleanUmkmId.isEmpty) {
      throw const AppException('ID UMKM tidak valid.');
    }

    try {
      final bytes = await _compressPhoto(file);
      final path =
          'umkm/$cleanUmkmId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bucket = _client.storage.from(AppBuckets.umkmPhotos);

      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      return bucket.getPublicUrl(path);
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal mengunggah foto. Coba lagi.',
      );
    }
  }

  Future<String> uploadCustomPath({
    required XFile file,
    required String path,
  }) async {
    try {
      final bytes = await _compressPhoto(file);
      final bucket = _client.storage.from(AppBuckets.umkmPhotos);

      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      return bucket.getPublicUrl(path);
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal mengunggah foto. Coba lagi.',
      );
    }
  }

  Future<void> deletePhotoByUrl(String publicUrl) async {
    if (publicUrl.trim().isEmpty) return;

    final path = _pathFromPublicUrl(publicUrl);
    if (path == null) {
      throw const AppException('URL foto tidak valid.');
    }

    try {
      await _client.storage.from(AppBuckets.umkmPhotos).remove([path]);
    } on Object catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal menghapus foto. Coba lagi.',
      );
    }
  }

  Future<Uint8List> _compressPhoto(XFile file) async {
    final originalBytes = await file.readAsBytes();
    if (originalBytes.isEmpty) {
      throw const AppException('Foto tidak dapat dibaca.');
    }

    const attempts = <({int size, int quality})>[
      (size: 1280, quality: 70),
      (size: 1280, quality: 60),
      (size: 1024, quality: 60),
      (size: 1024, quality: 50),
      (size: 768, quality: 50),
      (size: 640, quality: 45),
      (size: 512, quality: 40),
      (size: 384, quality: 35),
      (size: 256, quality: 30),
    ];

    Uint8List? bestBytes;
    for (final attempt in attempts) {
      final compressed = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: attempt.size,
        minHeight: attempt.size,
        quality: attempt.quality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      bestBytes = compressed;
      if (compressed.lengthInBytes <= _maxPhotoBytes) {
        return compressed;
      }
    }

    if (bestBytes == null || bestBytes.isEmpty) {
      throw const AppException('Foto gagal dikompres.');
    }
    if (bestBytes.lengthInBytes > _maxPhotoBytes) {
      throw const AppException('Foto masih terlalu besar setelah dikompres.');
    }
    return bestBytes;
  }

  String? _pathFromPublicUrl(String publicUrl) {
    final uri = Uri.tryParse(publicUrl);
    if (uri == null) return null;

    final bucketIndex = uri.pathSegments.indexOf(AppBuckets.umkmPhotos);
    if (bucketIndex < 0 || bucketIndex == uri.pathSegments.length - 1) {
      return null;
    }

    return uri.pathSegments.sublist(bucketIndex + 1).join('/');
  }
}
