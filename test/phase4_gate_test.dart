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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkmap/models/app_user.dart';
import 'package:umkmap/providers/auth_provider.dart';
import 'package:umkmap/services/auth_service.dart';
import 'package:umkmap/services/session_service.dart';
import 'package:umkmap/utils/app_exception.dart';
import 'package:umkmap/utils/app_router.dart';

const _user = AppUser(
  id: 'u-1',
  email: 'owner@umkmap.test',
  fullName: 'Owner Satu',
  role: 'pemilik',
);

/// AuthService double: no Supabase. [restoreUser] is what a persisted Supabase
/// session would resolve to on the next launch (null = session gone).
class _FakeAuthService implements AuthService {
  _FakeAuthService({this.signInResult, this.restoreUser});

  final AppUser? signInResult;
  final AppUser? restoreUser;

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
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
  Future<AppUser?> restore() async => restoreUser;
}

Future<GoRouter> _pumpRouterApp(
  WidgetTester tester,
  AuthProvider provider,
) async {
  final router = createAppRouter(provider);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: provider,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  test('T-01b: fresh provider restores persisted session (app restart)', () async {
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
  });

  test('rememberMe=false does not persist → restart falls back to guest', () async {
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
  });

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

  testWidgets('guest router guard allows only public list/map/detail routes', (
    tester,
  ) async {
    final provider = AuthProvider(
      authService: _FakeAuthService(),
      sessionService: const SessionService(),
    )..continueAsGuest();
    final router = await _pumpRouterApp(tester, provider);

    router.go('/umkm');
    await tester.pumpAndSettle();
    expect(find.text('Daftar UMKM'), findsOneWidget);

    router.go('/map');
    await tester.pumpAndSettle();
    expect(find.text('Peta'), findsOneWidget);

    router.go('/umkm/123');
    await tester.pumpAndSettle();
    expect(find.text('Detail UMKM: 123'), findsOneWidget);

    for (final protectedRoute in ['/dashboard', '/profile', '/umkm-form']) {
      router.go(protectedRoute);
      await tester.pumpAndSettle();
      expect(find.text('Masuk'), findsWidgets);
    }
  });

  testWidgets('authenticated router guard sends auth routes to dashboard', (
    tester,
  ) async {
    final provider = AuthProvider(
      authService: _FakeAuthService(signInResult: _user),
      sessionService: const SessionService(),
    );
    await provider.login('owner@umkmap.test', 'password123', rememberMe: true);
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
