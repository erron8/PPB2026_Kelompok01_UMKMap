import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/supabase_client.dart';
import '../models/umkm_report.dart';
import '../utils/app_exception.dart';

class ReportService {
  const ReportService();

  SupabaseClient get _client => AppSupabase.client;

  static const _selectColumns = '''
    id,
    umkm_id,
    reporter_id,
    tipe_laporan,
    deskripsi,
    foto_bukti_url,
    status,
    created_at,
    umkm:umkm_id(nama_usaha),
    reporter:reporter_id(full_name)
  ''';

  Future<UmkmReport> insertReport({
    required String umkmId,
    required String reporterId,
    required String tipeLaporan,
    required String deskripsi,
    required String fotoBuktiUrl,
  }) async {
    try {
      final data = await _client.from('reports').insert({
        'umkm_id': umkmId,
        'reporter_id': reporterId,
        'tipe_laporan': tipeLaporan,
        'deskripsi': deskripsi,
        'foto_bukti_url': fotoBuktiUrl,
      }).select(_selectColumns).single();

      return UmkmReport.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<UmkmReport>> fetchPendingReports() async {
    try {
      final data = await _client
          .from('reports')
          .select(_selectColumns)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => UmkmReport.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<UmkmReport> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    try {
      final data = await _client
          .from('reports')
          .update({'status': status})
          .eq('id', reportId)
          .select(_selectColumns)
          .single();

      return UmkmReport.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
