import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_client.dart';
import '../models/app_user.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

class AuthService {
  const AuthService();

  SupabaseClient get _client => AppSupabase.client;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AppException('Email atau kata sandi salah');
      }
      return _currentProfile(user);
    } on AppException {
      rethrow;
    } on AuthException {
      throw const AppException('Email atau kata sandi salah');
    } catch (_) {
      throw const AppException('Gagal masuk. Periksa koneksi internet Anda.');
    }
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      final user = response.user;
      if (user == null) {
        throw const AppException('Pendaftaran gagal. Coba lagi.');
      }
      return AppUser(
        id: user.id,
        email: user.email ?? email,
        fullName: fullName,
        role: 'pemilik',
      );
    } on AppException {
      rethrow;
    } on AuthException catch (error) {
      throw AppException(error.message);
    } catch (_) {
      throw const AppException(
        'Pendaftaran gagal. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      throw const AppException('Gagal keluar. Coba lagi.');
    }
  }

  Future<AppUser?> restore() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return _currentProfile(user);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> _currentProfile(User user) async {
    final data = await _client
        .from(AppTables.profiles)
        .select('id, full_name, role')
        .eq('id', user.id)
        .single();

    return AppUser.fromJson({...data, 'email': user.email ?? ''});
  }
}
