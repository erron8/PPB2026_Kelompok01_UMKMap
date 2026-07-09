import '../models/umkm.dart';

class Formatters {
  const Formatters._();

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String date(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    return '$day ${_monthNames[local.month - 1]} ${local.year}';
  }

  static String address(Umkm umkm) {
    final parts = [
      umkm.alamatJalan,
      umkm.kecamatanNama,
      umkm.kotaNama,
      umkm.provinsiNama,
    ].where((part) => part != null && part.trim().isNotEmpty);

    return parts.join(', ');
  }

  static String coordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
