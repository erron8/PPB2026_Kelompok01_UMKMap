class Kategori {
  const Kategori({required this.id, required this.nama});

  final int id;
  final String nama;

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(id: json['id'] as int, nama: json['nama'] as String);
  }
}
