class Wilayah {
  const Wilayah({required this.id, required this.name});

  final String id;
  final String name;

  factory Wilayah.fromJson(Map<String, dynamic> json) {
    return Wilayah(id: json['id'] as String, name: json['name'] as String);
  }
}
