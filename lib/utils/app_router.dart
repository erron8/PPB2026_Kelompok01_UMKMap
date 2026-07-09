import 'package:go_router/go_router.dart';

import '../models/umkm.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/map_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/umkm_detail_screen.dart';
import '../screens/umkm_form_screen.dart';
import '../screens/umkm_list_screen.dart';

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/umkm',
        name: 'umkm-list',
        builder: (context, state) => const UmkmListScreen(),
      ),
      GoRoute(
        path: '/umkm/:id',
        name: 'umkm-detail',
        builder: (context, state) =>
            UmkmDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/umkm-form',
        name: 'umkm-form',
        builder: (context, state) => UmkmFormScreen(
          initialUmkm: state.extra is Umkm ? state.extra as Umkm : null,
        ),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isPublicRoute =
          location == '/splash' ||
          location == '/login' ||
          location == '/register' ||
          location == '/umkm' ||
          location.startsWith('/umkm/') ||
          location == '/map';

      if (authProvider.status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }

      if (authProvider.status == AuthStatus.authenticated) {
        if (location == '/splash' || isAuthRoute) return '/dashboard';
        return null;
      }

      if (location == '/splash') return '/login';
      if (!isPublicRoute) return '/login';
      return null;
    },
  );
}
