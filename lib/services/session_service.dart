import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../utils/constants.dart';

class SessionService {
  const SessionService();

  Future<void> save(AppUser user, {required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.userId, user.id);
    await prefs.setString(PrefKeys.role, user.role);
    await prefs.setString(PrefKeys.email, user.email);
    await prefs.setBool(PrefKeys.rememberMe, rememberMe);
  }

  Future<({String userId, String role, String email})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(PrefKeys.rememberMe) ?? false;
    final userId = prefs.getString(PrefKeys.userId);
    final role = prefs.getString(PrefKeys.role);
    final email = prefs.getString(PrefKeys.email);

    if (!rememberMe || userId == null || role == null || email == null) {
      return null;
    }

    return (userId: userId, role: role, email: email);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.userId);
    await prefs.remove(PrefKeys.role);
    await prefs.remove(PrefKeys.email);
    await prefs.remove(PrefKeys.rememberMe);
  }
}
