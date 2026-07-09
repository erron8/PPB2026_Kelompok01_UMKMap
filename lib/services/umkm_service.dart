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
    } catch (_) {
      throw const AppException('Gagal memuat kategori UMKM.');
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
    } catch (_) {
      throw const AppException(
        'Gagal memuat data UMKM. Periksa koneksi internet Anda.',
      );
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
    } catch (_) {
      throw const AppException(
        'Gagal memuat detail UMKM. Periksa koneksi internet Anda.',
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
    } catch (_) {
      throw const AppException('Gagal memuat statistik UMKM.');
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

      final data = await query;
      return (data as List<dynamic>).length;
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }
}
