class UmkmReport {
  const UmkmReport({
    required this.id,
    required this.umkmId,
    required this.reporterId,
    required this.tipeLaporan,
    required this.deskripsi,
    required this.fotoBuktiUrl,
    required this.status,
    required this.createdAt,
    this.umkmNama,
    this.reporterNama,
  });

  final String id;
  final String umkmId;
  final String reporterId;
  final String tipeLaporan;
  final String deskripsi;
  final String fotoBuktiUrl;
  final String status;
  final DateTime createdAt;
  final String? umkmNama;
  final String? reporterNama;

  factory UmkmReport.fromJson(Map<String, dynamic> json) {
    return UmkmReport(
      id: json['id'] as String,
      umkmId: json['umkm_id'] as String,
      reporterId: json['reporter_id'] as String,
      tipeLaporan: json['tipe_laporan'] as String,
      deskripsi: json['deskripsi'] as String,
      fotoBuktiUrl: json['foto_bukti_url'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      umkmNama: _umkmNamaFromJson(json['umkm']),
      reporterNama: _reporterNamaFromJson(json['reporter']),
    );
  }

  static String? _umkmNamaFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return value['nama_usaha'] as String?;
    }
    return null;
  }

  static String? _reporterNamaFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return value['full_name'] as String?;
    }
    return null;
  }
}
