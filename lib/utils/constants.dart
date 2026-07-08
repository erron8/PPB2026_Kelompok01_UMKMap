import 'package:flutter/material.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'UMKMap';
}

class AppTables {
  const AppTables._();

  static const profiles = 'profiles';
  static const kategoriUmkm = 'kategori_umkm';
  static const umkm = 'umkm';
}

class AppBuckets {
  const AppBuckets._();

  static const umkmPhotos = 'umkm-photos';
}

class PrefKeys {
  const PrefKeys._();

  static const sessionUserId = 'session_user_id';
  static const sessionRole = 'session_role';
  static const sessionEmail = 'session_email';
  static const rememberMe = 'remember_me';
}

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF00796B);
  static const secondary = Color(0xFFFFB300);
  static const background = Color(0xFFF7F9F8);
  static const error = Color(0xFFD32F2F);
}
