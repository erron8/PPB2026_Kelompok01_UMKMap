import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_exception.dart';
import '../utils/constants.dart';

class AppSupabase {
  const AppSupabase._();

  static Future<void> initialize() async {
    if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
      throw const AppException(
        'Konfigurasi Supabase belum tersedia. Jalankan aplikasi dengan '
        'SUPABASE_URL dan SUPABASE_ANON_KEY.',
      );
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
