class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.poin = 0,
    String? tier,
    this.phone,
  }) : _tier = tier;

  final String id;
  final String email;
  final String fullName;
  final String role;
  final int poin;
  final String? _tier;
  final String? phone;

  bool get isAdmin => role == 'admin';

  String get tier {
    if (_tier != null) return _tier;
    if (poin <= 100) return 'Bronze';
    if (poin <= 200) return 'Silver';
    if (poin <= 300) return 'Gold';
    if (poin <= 400) return 'Platinum';
    return 'Super User';
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Pengguna',
      role: json['role'] as String? ?? 'pemilik',
      poin: json['poin'] as int? ?? 0,
      tier: json['tier'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
