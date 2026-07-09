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

  static const primary = 0xFF5C6B2F;
  static const onPrimary = 0xFFFFFFFF;
  static const secondary = 0xFFA5C34C;
  static const onSecondary = 0xFF2F3A14;
  static const primaryContainer = 0xFFE8F0D2;
  static const onPrimaryContainer = 0xFF3A431C;
  static const background = 0xFFF4F5F0;
  static const surface = 0xFFFFFFFF;
  static const fieldFill = 0xFFEFF1E8;
  static const hairline = 0xFFE3E6DA;
  static const error = 0xFFD32F2F;
  static const textPrimary = 0xFF2B2B26;
  static const textMuted = 0xFF5F6552;
  static const textSubtle = 0xFF7A7F6C;
  static const textFaint = 0xFF9AA089;
  static const oliveGrey = 0xFF8A9070;
  static const dragHandle = 0xFFDDE1D3;
  static const photoDash = 0xFFC9D1B4;
  static const userLocation = 0xFF1976D2;

  static const statusVerifiedText = 0xFF2E7D32;
  static const statusVerifiedFill = 0xFFE3F0DC;
  static const statusPendingText = 0xFFB26A00;
  static const statusPendingFill = 0xFFF6EBD4;
  static const statusRejectedText = 0xFFC62828;
  static const statusRejectedFill = 0xFFF7DFDD;

  static const markerPalette = <int>[
    0xFF5C6B2F,
    0xFF8FAE3E,
    0xFFC4703A,
    0xFFD9A62E,
    0xFF3E7C6B,
    0xFF7A5B6E,
  ];
}

class AppRadii {
  const AppRadii._();

  static const radiusPill = 999.0;
  static const radiusCard = 16.0;
  static const radiusThumb = 12.0;
  static const radiusSheet = 24.0;
}
