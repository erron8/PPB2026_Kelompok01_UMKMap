class Umkm {
  const Umkm({
    required this.id,
    required this.ownerId,
    required this.namaUsaha,
    required this.namaPemilik,
    required this.kategoriId,
    this.kategoriNama,
    this.deskripsi,
    this.alamatJalan,
    required this.provinsiId,
    required this.provinsiNama,
    required this.kotaId,
    required this.kotaNama,
    required this.kecamatanId,
    required this.kecamatanNama,
    required this.latitude,
    required this.longitude,
    this.fotoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String namaUsaha;
  final String namaPemilik;
  final int kategoriId;
  final String? kategoriNama;
  final String? deskripsi;
  final String? alamatJalan;
  final String provinsiId;
  final String provinsiNama;
  final String kotaId;
  final String kotaNama;
  final String kecamatanId;
  final String kecamatanNama;
  final double latitude;
  final double longitude;
  final String? fotoUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Umkm.fromJson(Map<String, dynamic> json) {
    return Umkm(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      namaUsaha: json['nama_usaha'] as String,
      namaPemilik: json['nama_pemilik'] as String,
      kategoriId: json['kategori_id'] as int,
      kategoriNama: _kategoriNamaFromJson(json['kategori_umkm']),
      deskripsi: json['deskripsi'] as String?,
      alamatJalan: json['alamat_jalan'] as String?,
      provinsiId: json['provinsi_id'] as String,
      provinsiNama: json['provinsi_nama'] as String,
      kotaId: json['kota_id'] as String,
      kotaNama: json['kota_nama'] as String,
      kecamatanId: json['kecamatan_id'] as String,
      kecamatanNama: json['kecamatan_nama'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fotoUrl: json['foto_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'owner_id': ownerId,
      'nama_usaha': namaUsaha,
      'nama_pemilik': namaPemilik,
      'kategori_id': kategoriId,
      'deskripsi': deskripsi,
      'alamat_jalan': alamatJalan,
      'provinsi_id': provinsiId,
      'provinsi_nama': provinsiNama,
      'kota_id': kotaId,
      'kota_nama': kotaNama,
      'kecamatan_id': kecamatanId,
      'kecamatan_nama': kecamatanNama,
      'latitude': latitude,
      'longitude': longitude,
      'foto_url': fotoUrl,
      'status': status,
    };
  }

  Umkm copyWith({
    String? id,
    String? ownerId,
    String? namaUsaha,
    String? namaPemilik,
    int? kategoriId,
    String? kategoriNama,
    String? deskripsi,
    String? alamatJalan,
    String? provinsiId,
    String? provinsiNama,
    String? kotaId,
    String? kotaNama,
    String? kecamatanId,
    String? kecamatanNama,
    double? latitude,
    double? longitude,
    String? fotoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Umkm(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      namaUsaha: namaUsaha ?? this.namaUsaha,
      namaPemilik: namaPemilik ?? this.namaPemilik,
      kategoriId: kategoriId ?? this.kategoriId,
      kategoriNama: kategoriNama ?? this.kategoriNama,
      deskripsi: deskripsi ?? this.deskripsi,
      alamatJalan: alamatJalan ?? this.alamatJalan,
      provinsiId: provinsiId ?? this.provinsiId,
      provinsiNama: provinsiNama ?? this.provinsiNama,
      kotaId: kotaId ?? this.kotaId,
      kotaNama: kotaNama ?? this.kotaNama,
      kecamatanId: kecamatanId ?? this.kecamatanId,
      kecamatanNama: kecamatanNama ?? this.kecamatanNama,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _kategoriNamaFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return value['nama'] as String?;
    }
    return null;
  }
}

class UmkmInput {
  const UmkmInput({
    required this.ownerId,
    required this.namaUsaha,
    required this.namaPemilik,
    required this.kategoriId,
    this.deskripsi,
    this.alamatJalan,
    required this.provinsiId,
    required this.provinsiNama,
    required this.kotaId,
    required this.kotaNama,
    required this.kecamatanId,
    required this.kecamatanNama,
    required this.latitude,
    required this.longitude,
    this.fotoUrl,
  });

  final String ownerId;
  final String namaUsaha;
  final String namaPemilik;
  final int kategoriId;
  final String? deskripsi;
  final String? alamatJalan;
  final String provinsiId;
  final String provinsiNama;
  final String kotaId;
  final String kotaNama;
  final String kecamatanId;
  final String kecamatanNama;
  final double latitude;
  final double longitude;
  final String? fotoUrl;

  UmkmInput withFotoUrl(String? value) {
    return UmkmInput(
      ownerId: ownerId,
      namaUsaha: namaUsaha,
      namaPemilik: namaPemilik,
      kategoriId: kategoriId,
      deskripsi: deskripsi,
      alamatJalan: alamatJalan,
      provinsiId: provinsiId,
      provinsiNama: provinsiNama,
      kotaId: kotaId,
      kotaNama: kotaNama,
      kecamatanId: kecamatanId,
      kecamatanNama: kecamatanNama,
      latitude: latitude,
      longitude: longitude,
      fotoUrl: value,
    );
  }

  Map<String, dynamic> toInsertJson({required String id}) {
    return {
      'id': id,
      'owner_id': ownerId,
      'nama_usaha': namaUsaha,
      'nama_pemilik': namaPemilik,
      'kategori_id': kategoriId,
      'deskripsi': deskripsi,
      'alamat_jalan': alamatJalan,
      'provinsi_id': provinsiId,
      'provinsi_nama': provinsiNama,
      'kota_id': kotaId,
      'kota_nama': kotaNama,
      'kecamatan_id': kecamatanId,
      'kecamatan_nama': kecamatanNama,
      'latitude': latitude,
      'longitude': longitude,
      'foto_url': fotoUrl,
      'status': 'pending',
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nama_usaha': namaUsaha,
      'nama_pemilik': namaPemilik,
      'kategori_id': kategoriId,
      'deskripsi': deskripsi,
      'alamat_jalan': alamatJalan,
      'provinsi_id': provinsiId,
      'provinsi_nama': provinsiNama,
      'kota_id': kotaId,
      'kota_nama': kotaNama,
      'kecamatan_id': kecamatanId,
      'kecamatan_nama': kecamatanNama,
      'latitude': latitude,
      'longitude': longitude,
      'foto_url': fotoUrl,
    };
  }
}
