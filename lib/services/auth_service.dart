import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_client.dart';
import '../models/app_user.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

typedef AuthSignInWithPassword =
    Future<AuthResponse> Function({
      required String email,
      required String password,
    });

typedef AuthSignUpWithPassword =
    Future<AuthResponse> Function({
      required String email,
      required String password,
      Map<String, dynamic>? data,
    });

class AuthService {
  const AuthService({
    AuthSignInWithPassword? signInWithPassword,
    AuthSignUpWithPassword? signUpWithPassword,
  }) : _signInWithPassword = signInWithPassword,
       _signUpWithPassword = signUpWithPassword;

  final AuthSignInWithPassword? _signInWithPassword;
  final AuthSignUpWithPassword? _signUpWithPassword;

  SupabaseClient get _client => AppSupabase.client;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final signInWithPassword = _signInWithPassword;
      final response = signInWithPassword == null
          ? await _client.auth.signInWithPassword(
              email: email,
              password: password,
            )
          : await signInWithPassword(email: email, password: password);
      final user = response.user;
      if (user == null) {
        throw const AppException('Email atau kata sandi salah');
      }
      return _currentProfile(user);
    } on AppException {
      rethrow;
    } on AuthException catch (error) {
      if (AppException.isNetworkError(error)) {
        throw const AppException(AppException.offlineMessage);
      }
      throw AppException(_signInAuthMessage(error));
    } catch (error) {
      throw AppException.fromObject(error, fallback: 'Gagal masuk. Coba lagi.');
    }
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final signUpWithPassword = _signUpWithPassword;
      final response = signUpWithPassword == null
          ? await _client.auth.signUp(
              email: email,
              password: password,
              data: {'full_name': fullName},
            )
          : await signUpWithPassword(
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
      if (AppException.isNetworkError(error)) {
        throw const AppException(AppException.offlineMessage);
      }
      throw AppException(_signUpAuthMessage(error));
    } catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Pendaftaran gagal. Coba lagi.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw AppException.fromObject(
        error,
        fallback: 'Gagal keluar. Coba lagi.',
      );
    }
  }

  Future<AppUser?> restore() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _currentProfile(user);
    } on AppException {
      rethrow;
    } catch (error) {
      // A network failure must not be mistaken for "no session"; surface it so
      // the caller can offer a retry instead of silently logging the user out.
      if (AppException.isNetworkError(error)) {
        throw const AppException(AppException.offlineMessage);
      }
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

  static String _signInAuthMessage(AuthException error) {
    if (_isRateLimited(error)) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }

    switch (error.code) {
      case 'email_not_confirmed':
        return 'Email belum dikonfirmasi. Periksa email Anda untuk tautan konfirmasi.';
      case 'invalid_credentials':
      default:
        return 'Email atau kata sandi salah';
    }
  }

  static String _signUpAuthMessage(AuthException error) {
    if (_isRateLimited(error)) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }

    switch (error.code) {
      case 'user_already_exists':
        return 'Email sudah terdaftar. Silakan masuk.';
      default:
        return 'Pendaftaran gagal. Coba lagi.';
    }
  }

  static bool _isRateLimited(AuthException error) {
    return error.code == 'over_email_send_rate_limit' ||
        error.statusCode == '429';
  }
}
