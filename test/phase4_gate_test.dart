// Phase 4 gate — Auth, Session & Routing (§5.1, §11.7–11.10).
//
// Hermetic reconstruction of T-01/T-02/T-03 at the AuthProvider + SessionService
// level: no live Supabase, no device. AuthService is faked; SessionService runs
// against mocked SharedPreferences. This exercises the real persistence and
// state-machine logic plus the real go_router redirect guard. Physical-device
// verification remains for Phase 13 QA.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umkmap/main.dart';
import 'package:umkmap/models/kategori.dart';
import 'package:umkmap/models/app_user.dart';
import 'package:umkmap/models/umkm.dart';
import 'package:umkmap/providers/auth_provider.dart';
import 'package:umkmap/providers/location_provider.dart';
import 'package:umkmap/providers/umkm_provider.dart';
import 'package:umkmap/services/auth_service.dart';
import 'package:umkmap/services/location_service.dart';
import 'package:umkmap/services/session_service.dart';
import 'package:umkmap/services/umkm_service.dart';
import 'package:umkmap/utils/app_exception.dart';
import 'package:umkmap/utils/app_router.dart';

const _user = AppUser(
  id: 'u-1',
  email: 'owner@example.com',
  fullName: 'Owner Satu',
  role: 'pemilik',
);

/// AuthService double: no Supabase. [restoreUser] is what a persisted Supabase
/// session would resolve to on the next launch (null = session gone).
class _FakeAuthService implements AuthService {
  _FakeAuthService({this.signInResult, this.restoreUser, this.restoreError});

  final AppUser? signInResult;
  AppUser? restoreUser;

  /// When set, [restore] throws this instead of returning [restoreUser],
  /// simulating an offline / failed startup network call. Mutable so a test
  /// can clear it to model connectivity returning between retries.
  Object? restoreError;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final result = signInResult;
    if (result == null) throw const AppException('Email atau kata sandi salah');
    return result;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser?> restore() async {
    final error = restoreError;
    if (error != null) throw error;
    return restoreUser;
  }

  @override
  Future<AppUser> updateProfile({
    required String id,
    required String fullName,
    required String? phone,
  }) async {
    return AppUser(
      id: id,
      email: restoreUser?.email ?? 'owner@example.com',
      fullName: fullName,
      role: restoreUser?.role ?? 'pemilik',
      poin: restoreUser?.poin ?? 0,
      phone: phone,
    );
  }
}

Future<GoRouter> _pumpRouterApp(
  WidgetTester tester,
  AuthProvider provider,
) async {
  final router = createAppRouter(provider);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: provider),
        ChangeNotifierProvider<UmkmProvider>(
          create: (_) => UmkmProvider(service: const _EmptyUmkmService()),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) =>
              LocationProvider(service: const _FakeLocationService()),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<String> _signInMessageFrom(AuthException error) async {
  final service = AuthService(
    signInWithPassword:
        ({required String email, required String password}) async {
          throw error;
        },
  );

  try {
    await service.signIn(email: 'owner@example.com', password: 'test-password');
    fail('Expected AuthService.signIn to throw AppException');
  } on AppException catch (appError) {
    return appError.message;
  }
}

Future<String> _signUpMessageFrom(AuthException error) async {
  final service = AuthService(
    signUpWithPassword:
        ({
          required String email,
          required String password,
          Map<String, dynamic>? data,
        }) async {
          throw error;
        },
  );

  try {
    await service.signUp(
      email: 'owner@example.com',
      password: 'test-password',
      fullName: 'Owner Satu',
    );
    fail('Expected AuthService.signUp to throw AppException');
  } on AppException catch (appError) {
    return appError.message;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthService signIn AuthException mapping', () {
    test('email_not_confirmed explains that confirmation is required', () async {
      final message = await _signInMessageFrom(
        const AuthException(
          'Email not confirmed',
          statusCode: '400',
          code: 'email_not_confirmed',
        ),
      );

      expect(
        message,
        'Email belum dikonfirmasi. Periksa email Anda untuk tautan konfirmasi.',
      );
    });

    test('over_email_send_rate_limit explains the retry limit', () async {
      final message = await _signInMessageFrom(
        const AuthException(
          'Email rate limit exceeded',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
      );

      expect(message, 'Terlalu banyak percobaan. Coba lagi nanti.');
    });

    test('HTTP 429 without code still explains the retry limit', () async {
      final message = await _signInMessageFrom(
        const AuthException('Too many requests', statusCode: '429'),
      );

      expect(message, 'Terlalu banyak percobaan. Coba lagi nanti.');
    });

    test('invalid_credentials keeps the existing login error', () async {
      final message = await _signInMessageFrom(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );

      expect(message, 'Email atau kata sandi salah');
    });

    test('unknown auth code falls back to the login error', () async {
      final message = await _signInMessageFrom(
        const AuthException(
          'Unexpected auth error',
          statusCode: '400',
          code: 'unexpected_auth_error',
        ),
      );

      expect(message, 'Email atau kata sandi salah');
    });
  });

  group('AuthService signUp AuthException mapping', () {
    test('over_email_send_rate_limit explains the retry limit', () async {
      final message = await _signUpMessageFrom(
        const AuthException(
          'Email rate limit exceeded',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
      );

      expect(message, 'Terlalu banyak percobaan. Coba lagi nanti.');
    });

    test('HTTP 429 without code still explains the retry limit', () async {
      final message = await _signUpMessageFrom(
        const AuthException('Too many requests', statusCode: '429'),
      );

      expect(message, 'Terlalu banyak percobaan. Coba lagi nanti.');
    });

    test('user_already_exists explains that the account exists', () async {
      final message = await _signUpMessageFrom(
        const AuthException(
          'User already registered',
          statusCode: '422',
          code: 'user_already_exists',
        ),
      );

      expect(message, 'Email sudah terdaftar. Silakan masuk.');
    });
  });

  test('T-01a: login with rememberMe persists session', () async {
    const session = SessionService();
    final provider = AuthProvider(
      authService: _FakeAuthService(signInResult: _user),
      sessionService: session,
    );

    final ok = await provider.login('e', 'p', rememberMe: true);

    expect(ok, isTrue);
    expect(provider.status, AuthStatus.authenticated);
    expect(provider.user?.id, 'u-1');
    expect(await session.load(), isNotNull); // survived to prefs
  });

  test(
    'T-01b: fresh provider restores persisted session (app restart)',
    () async {
      const session = SessionService();
      // First run: log in and persist.
      await AuthProvider(
        authService: _FakeAuthService(signInResult: _user),
        sessionService: session,
      ).login('e', 'p', rememberMe: true);

      // Second run: new provider, Supabase session still valid.
      final restarted = AuthProvider(
        authService: _FakeAuthService(restoreUser: _user),
        sessionService: session,
      );
      await restarted.restoreSession();

      expect(restarted.status, AuthStatus.authenticated);
      expect(restarted.user?.id, 'u-1');
    },
  );

  test(
    'T-01c: offline restore stays retriable instead of hanging or logging out',
    () async {
      const session = SessionService();
      await AuthProvider(
        authService: _FakeAuthService(signInResult: _user),
        sessionService: session,
      ).login('e', 'p', rememberMe: true);

      // Second run while offline: the profile fetch fails with a network error.
      final fakeAuth = _FakeAuthService(
        restoreError: const AppException(AppException.offlineMessage),
      );
      final restarted = AuthProvider(
        authService: fakeAuth,
        sessionService: session,
      );
      await restarted.restoreSession();

      // Stays on the splash (unknown) with the retry flag, and the persisted
      // session is preserved so a retry can succeed.
      expect(restarted.status, AuthStatus.unknown);
      expect(restarted.startupFailedOffline, isTrue);
      expect(await session.load(), isNotNull);

      // Connectivity returns: retrying resolves the session, no restart needed.
      fakeAuth
        ..restoreError = null
        ..restoreUser = _user;
      await restarted.restoreSession();

      expect(restarted.startupFailedOffline, isFalse);
      expect(restarted.status, AuthStatus.authenticated);
      expect(restarted.user?.id, 'u-1');
    },
  );

  test(
    'rememberMe=false does not persist → restart falls back to guest',
    () async {
      const session = SessionService();
      await AuthProvider(
        authService: _FakeAuthService(signInResult: _user),
        sessionService: session,
      ).login('e', 'p', rememberMe: false);

      expect(await session.load(), isNull);

      final restarted = AuthProvider(
        authService: _FakeAuthService(restoreUser: _user),
        sessionService: session,
      );
      await restarted.restoreSession();
      expect(restarted.status, AuthStatus.guest);
    },
  );

  test('T-02: wrong password → login false, inline error message', () async {
    final provider = AuthProvider(
      authService: _FakeAuthService(signInResult: null),
      sessionService: const SessionService(),
    );

    final ok = await provider.login('e', 'bad', rememberMe: true);

    expect(ok, isFalse);
    expect(provider.status, AuthStatus.unknown);
    expect(provider.errorMessage, 'Email atau kata sandi salah');
  });

  test('T-03: logout clears persisted prefs and returns to guest', () async {
    const session = SessionService();
    final provider = AuthProvider(
      authService: _FakeAuthService(signInResult: _user),
      sessionService: session,
    );
    await provider.login('e', 'p', rememberMe: true);
    expect(await session.load(), isNotNull);

    await provider.logout();

    expect(provider.status, AuthStatus.guest);
    expect(provider.user, isNull);
    expect(await session.load(), isNull); // prefs cleared
  });

  test('guest: continueAsGuest sets guest status without a user', () {
    final provider = AuthProvider(
      authService: _FakeAuthService(),
      sessionService: const SessionService(),
    );

    provider.continueAsGuest();

    expect(provider.status, AuthStatus.guest);
    expect(provider.isGuest, isTrue);
    expect(provider.user, isNull);
  });

  testWidgets('guest button lands on dashboard and stays there', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut sebagai tamu'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Halo, Tamu'), findsOneWidget);
    expect(find.text('Anda masuk sebagai tamu.'), findsOneWidget);
  });

  testWidgets('guest router guard allows public dashboard/list/map/detail', (
    tester,
  ) async {
    final provider = AuthProvider(
      authService: _FakeAuthService(),
      sessionService: const SessionService(),
    )..continueAsGuest();
    final router = await _pumpRouterApp(tester, provider);

    router.go('/dashboard');
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Halo, Tamu'), findsOneWidget);
    expect(find.text('Anda masuk sebagai tamu.'), findsOneWidget);

    router.go('/umkm');
    await tester.pumpAndSettle();
    expect(find.text('Daftar UMKM'), findsOneWidget);

    router.go('/map');
    await tester.pumpAndSettle();
    expect(find.text('Peta UMKM'), findsOneWidget);

    router.go('/umkm/123');
    await tester.pumpAndSettle();
    expect(find.text('Detail UMKM'), findsOneWidget);

    for (final protectedRoute in ['/profile', '/umkm-form']) {
      router.go(protectedRoute);
      await tester.pumpAndSettle();
      expect(find.text('Masuk'), findsWidgets);
    }
  });

  testWidgets('guest dashboard shows login-required dialog for tambah UMKM', (
    tester,
  ) async {
    final provider = AuthProvider(
      authService: _FakeAuthService(),
      sessionService: const SessionService(),
    )..continueAsGuest();
    final router = await _pumpRouterApp(tester, provider);

    router.go('/dashboard');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah UMKM'));
    await tester.pumpAndSettle();

    expect(find.text('Perlu Masuk'), findsOneWidget);
    expect(
      find.text(
        'Fitur ini hanya tersedia untuk pengguna yang sudah masuk. '
        'Masuk terlebih dahulu untuk melanjutkan.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Nanti'));
    await tester.pumpAndSettle();
    expect(find.text('Perlu Masuk'), findsNothing);

    await tester.tap(find.text('Tambah UMKM'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk').last);
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('authenticated router guard sends auth routes to dashboard', (
    tester,
  ) async {
    final provider = AuthProvider(
      authService: _FakeAuthService(signInResult: _user),
      sessionService: const SessionService(),
    );
    await provider.login('owner@example.com', 'test-password', rememberMe: true);
    final router = await _pumpRouterApp(tester, provider);

    router.go('/login');
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Halo, Owner Satu'), findsOneWidget);

    router.go('/register');
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });
}

class _FakeLocationService implements LocationService {
  const _FakeLocationService();

  static const _point = LatLng(-5.147665, 119.432732);

  @override
  Future<LocationAvailability> ensurePermissionAndService() async {
    return LocationAvailability.ready;
  }

  @override
  Future<LatLng> current() async => _point;

  @override
  Stream<LatLng> stream() => Stream.value(_point);

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

class _EmptyUmkmService implements UmkmService {
  const _EmptyUmkmService();

  @override
  String newId() => '00000000-0000-4000-8000-000000000001';

  @override
  Future<List<Kategori>> fetchKategori() async => const [];

  @override
  Future<List<Umkm>> fetchList({
    String? search,
    int? kategoriId,
    String? kotaId,
    String? ownerId,
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    return const [];
  }

  @override
  Future<Umkm?> fetchById(String id) async => null;

  @override
  Future<Umkm> create({required String id, required UmkmInput input}) async {
    throw const AppException('not implemented');
  }

  @override
  Future<Umkm> update({required String id, required UmkmInput input}) async {
    throw const AppException('not implemented');
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<Umkm> setStatus({required String id, required String status}) async {
    throw const AppException('not implemented');
  }

  @override
  Future<DashboardStats> dashboardStats({String? ownerId}) async {
    return const DashboardStats(total: 0, verified: 0, pending: 0, rejected: 0);
  }
}
