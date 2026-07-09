class AppConfig {
  const AppConfig._();

  static const appName = 'UMKMap';
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const wilayahBaseUrl =
      'https://emsifa.github.io/api-wilayah-indonesia/api';
  static const nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
}

class AppTables {
  const AppTables._();

  static const profiles = 'profiles';
  static const umkm = 'umkm';
  static const kategori = 'kategori_umkm';
}

class AppBuckets {
  const AppBuckets._();

  static const umkmPhotos = 'umkm-photos';
}

class PrefKeys {
  const PrefKeys._();

  static const userId = 'session_user_id';
  static const role = 'session_role';
  static const email = 'session_email';
  static const rememberMe = 'remember_me';
}

class AppColors {
  const AppColors._();

  static const primary = 0xFF00796B;
  static const secondary = 0xFFFFB300;
  static const background = 0xFFF7F9F8;
  static const error = 0xFFD32F2F;
}
