import 'package:flutter_test/flutter_test.dart';
import 'package:umkmap/models/umkm.dart';

void main() {
  test('Umkm.fromJson toInsertJson preserves insert fields', () {
    final json = {
      'id': '9e82d670-0a65-463e-9ab0-84f8a29f58f7',
      'owner_id': '11766c98-2bbd-4794-93bb-6631d44cebe9',
      'nama_usaha': 'Warung Bu Sari',
      'nama_pemilik': 'Sari',
      'kategori_id': 1,
      'kategori_umkm': {'nama': 'Kuliner'},
      'deskripsi': 'Nasi campur dan minuman dingin.',
      'alamat_jalan': 'Jl. Merdeka No. 10',
      'provinsi_id': '51',
      'provinsi_nama': 'BALI',
      'kota_id': '5103',
      'kota_nama': 'KABUPATEN BADUNG',
      'kecamatan_id': '5103010',
      'kecamatan_nama': 'KUTA',
      'latitude': -8.7214,
      'longitude': 115.1686,
      'foto_url': 'https://example.com/umkm.jpg',
      'status': 'pending',
      'created_at': '2026-07-09T01:00:00.000Z',
      'updated_at': '2026-07-09T01:30:00.000Z',
    };

    final umkm = Umkm.fromJson(json);

    expect(umkm.kategoriNama, 'Kuliner');
    expect(umkm.toInsertJson(), {
      'owner_id': json['owner_id'],
      'nama_usaha': json['nama_usaha'],
      'nama_pemilik': json['nama_pemilik'],
      'kategori_id': json['kategori_id'],
      'deskripsi': json['deskripsi'],
      'alamat_jalan': json['alamat_jalan'],
      'provinsi_id': json['provinsi_id'],
      'provinsi_nama': json['provinsi_nama'],
      'kota_id': json['kota_id'],
      'kota_nama': json['kota_nama'],
      'kecamatan_id': json['kecamatan_id'],
      'kecamatan_nama': json['kecamatan_nama'],
      'latitude': json['latitude'],
      'longitude': json['longitude'],
      'foto_url': json['foto_url'],
      'status': json['status'],
      'detail_kategori': null,
      'hari_operasional': null,
      'jam_operasional': null,
    });
    expect(umkm.toInsertJson().containsKey('id'), isFalse);
    expect(umkm.toInsertJson().containsKey('created_at'), isFalse);
    expect(umkm.toInsertJson().containsKey('updated_at'), isFalse);
  });
}
