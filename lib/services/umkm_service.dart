import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_client.dart';
import '../models/kategori.dart';
import '../models/umkm.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.verified,
    required this.pending,
    required this.rejected,
  });

  final int total;
  final int verified;
  final int pending;
  final int rejected;
}

class UmkmService {
  const UmkmService();

  static const _selectColumns = '''
    id,
    owner_id,
    nama_usaha,
    nama_pemilik,
    kategori_id,
    kategori_umkm(nama),
    deskripsi,
    alamat_jalan,
    provinsi_id,
    provinsi_nama,
    kota_id,
    kota_nama,
    kecamatan_id,
    kecamatan_nama,
    latitude,
    longitude,
    foto_url,
    status,
    created_at,
    updated_at
  ''';

  SupabaseClient get _client => AppSupabase.client;

  String newId() => _uuidV4();

  Future<List<Kategori>> fetchKategori() async {
    try {
      final data = await _client
          .from(AppTables.kategori)
          .select('id, nama')
          .order('id', ascending: true);

      return (data as List<dynamic>)
          .map(
            (row) => Kategori.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    } catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal memuat kategori UMKM.',
      );
    }
  }

  Future<List<Umkm>> fetchList({
    String? search,
    int? kategoriId,
    String? kotaId,
    String? ownerId,
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final trimmedSearch = search?.trim();
      final trimmedKotaId = kotaId?.trim();
      final trimmedOwnerId = ownerId?.trim();

      dynamic query = _client.from(AppTables.umkm).select(_selectColumns);

      if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
        query = query.ilike('nama_usaha', '%$trimmedSearch%');
      }
      if (kategoriId != null) {
        query = query.eq('kategori_id', kategoriId);
      }
      if (trimmedKotaId != null && trimmedKotaId.isNotEmpty) {
        query = query.eq('kota_id', trimmedKotaId);
      }
      if (trimmedOwnerId != null && trimmedOwnerId.isNotEmpty) {
        query = query.eq('owner_id', trimmedOwnerId);
      }
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(from, to);

      return (data as List<dynamic>)
          .map((row) => Umkm.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    } catch (error) {
      throw AppException.fromObject(error, fallback: 'Gagal memuat data UMKM.');
    }
  }

  Future<Umkm?> fetchById(String id) async {
    try {
      final cleanId = id.trim();
      if (cleanId.isEmpty) return null;

      final data = await _client
          .from(AppTables.umkm)
          .select(_selectColumns)
          .eq('id', cleanId)
          .maybeSingle();

      if (data == null) return null;
      return Umkm.fromJson(Map<String, dynamic>.from(data));
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    } catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal memuat detail UMKM.',
      );
    }
  }

  Future<Umkm> create({required String id, required UmkmInput input}) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const AppException('ID UMKM tidak valid.');
    }

    try {
      final data = await _client
          .from(AppTables.umkm)
          .insert(input.toInsertJson(id: cleanId))
          .select(_selectColumns)
          .single();

      return Umkm.fromJson(Map<String, dynamic>.from(data));
    } on PostgrestException catch (error) {
      throw AppException(
        _friendlyPostgrestMessage(
          error,
          fallback: 'Gagal menyimpan UMKM baru.',
        ),
      );
    } catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal menyimpan UMKM baru.',
      );
    }
  }

  Future<Umkm> update({required String id, required UmkmInput input}) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const AppException('ID UMKM tidak valid.');
    }

    try {
      final data = await _client
          .from(AppTables.umkm)
          .update(input.toUpdateJson())
          .eq('id', cleanId)
          .select(_selectColumns)
          .single();

      return Umkm.fromJson(Map<String, dynamic>.from(data));
    } on PostgrestException catch (error) {
      throw AppException(
        _friendlyPostgrestMessage(error, fallback: 'Gagal memperbarui UMKM.'),
      );
    } catch (error) {
      throw AppException.fromObject(error, fallback: 'Gagal memperbarui UMKM.');
    }
  }

  Future<void> delete(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const AppException('ID UMKM tidak valid.');
    }

    try {
      final data = await _client
          .from(AppTables.umkm)
          .delete()
          .eq('id', cleanId)
          .select('id')
          .maybeSingle();

      if (data == null) {
        throw const AppException(
          'UMKM tidak ditemukan atau tidak dapat dihapus.',
        );
      }
    } on AppException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AppException(
        _friendlyPostgrestMessage(error, fallback: 'Gagal menghapus UMKM.'),
      );
    } catch (error) {
      throw AppException.fromObject(error, fallback: 'Gagal menghapus UMKM.');
    }
  }

  Future<Umkm> setStatus({required String id, required String status}) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const AppException('ID UMKM tidak valid.');
    }
    if (status != 'pending' && status != 'verified' && status != 'rejected') {
      throw const AppException('Status UMKM tidak valid.');
    }

    try {
      final data = await _client
          .from(AppTables.umkm)
          .update({'status': status})
          .eq('id', cleanId)
          .select(_selectColumns)
          .single();

      return Umkm.fromJson(Map<String, dynamic>.from(data));
    } on PostgrestException catch (error) {
      throw AppException(
        _friendlyPostgrestMessage(
          error,
          fallback: 'Gagal memperbarui status UMKM.',
        ),
      );
    } catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal memperbarui status UMKM.',
      );
    }
  }

  Future<DashboardStats> dashboardStats({String? ownerId}) async {
    try {
      final counts = await Future.wait<int>([
        _count(ownerId: ownerId),
        _count(ownerId: ownerId, status: 'verified'),
        _count(ownerId: ownerId, status: 'pending'),
        _count(ownerId: ownerId, status: 'rejected'),
      ]);

      return DashboardStats(
        total: counts[0],
        verified: counts[1],
        pending: counts[2],
        rejected: counts[3],
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal memuat statistik UMKM.',
      );
    }
  }

  Future<int> _count({String? ownerId, String? status}) async {
    try {
      dynamic query = _client.from(AppTables.umkm).select('id');

      final trimmedOwnerId = ownerId?.trim();
      if (trimmedOwnerId != null && trimmedOwnerId.isNotEmpty) {
        query = query.eq('owner_id', trimmedOwnerId);
      }
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final response = await query.limit(0).count(CountOption.exact);
      return response.count as int;
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    } catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal menghitung data UMKM.',
      );
    }
  }

  String _friendlyPostgrestMessage(
    PostgrestException error, {
    required String fallback,
  }) {
    if (AppException.isNetworkError(error)) {
      return AppException.offlineMessage;
    }
    final message = error.message.toLowerCase();
    if (message.contains('row-level security') ||
        message.contains('permission denied') ||
        message.contains('not authorized')) {
      return 'Anda tidak berwenang mengubah data UMKM ini.';
    }
    if (message.contains('0 rows') || error.code == 'PGRST116') {
      return 'UMKM tidak ditemukan atau tidak dapat diakses.';
    }
    return error.message.isEmpty ? fallback : error.message;
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(hexByte).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
