import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../utils/app_exception.dart';

enum AuthStatus { unknown, guest, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService authService = const AuthService(),
    SessionService sessionService = const SessionService(),
  }) : _authService = authService,
       _sessionService = sessionService;

  final AuthService _authService;
  final SessionService _sessionService;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  bool isLoading = false;
  String? errorMessage;

  bool get isAdmin => user?.isAdmin ?? false;
  bool get isGuest => status == AuthStatus.guest;

  Future<void> restoreSession() async {
    _setLoading(true);
    try {
      final savedSession = await _sessionService.load();
      final restoredUser = savedSession == null
          ? null
          : await _authService.restore();

      if (restoredUser == null) {
        await _sessionService.clear();
        user = null;
        status = AuthStatus.guest;
      } else {
        user = restoredUser;
        status = AuthStatus.authenticated;
      }
      errorMessage = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    _setLoading(true);
    try {
      final signedInUser = await _authService.signIn(
        email: email,
        password: password,
      );
      await _sessionService.save(signedInUser, rememberMe: rememberMe);
      user = signedInUser;
      status = AuthStatus.authenticated;
      errorMessage = null;
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      errorMessage = null;
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } on AppException {
      // Local logout always succeeds via the finally block, so a failed
      // network signOut must not leak an error onto the login screen.
    } finally {
      await _sessionService.clear();
      user = null;
      status = AuthStatus.guest;
      errorMessage = null;
      _setLoading(false);
    }
  }

  void continueAsGuest() {
    user = null;
    status = AuthStatus.guest;
    errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
