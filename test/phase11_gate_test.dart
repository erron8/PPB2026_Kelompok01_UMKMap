// Phase 11 gate — Dashboard & Profile (§6).
//
// Hermetic checks for role-scoped dashboard stats/recent rows and the live
// SharedPreferences proof tile on Profile. Live DB count verification remains
// part of the Phase 13 physical-device QA pass.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkmap/models/app_user.dart';
import 'package:umkmap/models/kategori.dart';
import 'package:umkmap/models/umkm.dart';
import 'package:umkmap/providers/auth_provider.dart';
import 'package:umkmap/providers/umkm_provider.dart';
import 'package:umkmap/screens/dashboard_screen.dart';
import 'package:umkmap/screens/profile_screen.dart';
import 'package:umkmap/services/storage_service.dart';
import 'package:umkmap/services/umkm_service.dart';
import 'package:umkmap/utils/app_exception.dart';
import 'package:umkmap/utils/constants.dart';

const _owner = AppUser(
  id: 'owner-1',
  email: 'pemilik1@umkmap.test',
  fullName: 'Pemilik Satu',
  role: 'pemilik',
);

const _admin = AppUser(
  id: 'admin-1',
  email: 'admin@umkmap.test',
  fullName: 'Admin UMKMap',
  role: 'admin',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('owner dashboard scopes stats and recent UMKM to owner id', (
    tester,
  ) async {
    final service = _DashboardUmkmService();
    await _pumpDashboard(tester, user: _owner, service: service);

    expect(service.statsOwnerIds, ['owner-1']);
    expect(service.fetchCalls.single.ownerId, 'owner-1');
    expect(service.fetchCalls.single.status, isNull);
    expect(find.text('Halo, Pemilik Satu'), findsOneWidget);
    expect(find.text('Pemilik'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Warung Owner'), findsOneWidget);
  });

  testWidgets('admin dashboard uses global stats and shows pending section', (
    tester,
  ) async {
    final service = _DashboardUmkmService();
    await _pumpDashboard(tester, user: _admin, service: service);

    expect(service.statsOwnerIds, [null]);
    expect(service.fetchCalls.map((call) => call.status), [null, 'pending']);
    expect(find.text('Halo, Admin UMKMap'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Menunggu Verifikasi'), findsWidgets);
    expect(find.text('UMKM Pending'), findsOneWidget);
  });

  testWidgets('profile shows all four SharedPreferences session values', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.userId: _owner.id,
      PrefKeys.role: _owner.role,
      PrefKeys.email: _owner.email,
      PrefKeys.rememberMe: true,
    });

    final auth = AuthProvider()
      ..status = AuthStatus.authenticated
      ..user = _owner;

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session info'), findsOneWidget);
    expect(find.text(PrefKeys.userId), findsOneWidget);
    expect(find.text(_owner.id), findsOneWidget);
    expect(find.text(PrefKeys.role), findsOneWidget);
    expect(find.text(_owner.role), findsWidgets);
    expect(find.text(PrefKeys.email), findsOneWidget);
    expect(find.text(_owner.email), findsWidgets);
    expect(find.text(PrefKeys.rememberMe), findsOneWidget);
    expect(find.text('true'), findsOneWidget);
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required AppUser user,
  required _DashboardUmkmService service,
}) async {
  final auth = AuthProvider()
    ..status = AuthStatus.authenticated
    ..user = user;
  final provider = UmkmProvider(
    service: service,
    storageService: const _NoopStorageService(),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<UmkmProvider>.value(value: provider),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _DashboardUmkmService implements UmkmService {
  final List<String?> statsOwnerIds = [];
  final List<_FetchCall> fetchCalls = [];

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
    fetchCalls.add(_FetchCall(ownerId: ownerId, status: status));
    if (status == 'pending') {
      return [_umkm('pending-1', 'UMKM Pending', status: 'pending')];
    }
    return [
      _umkm('recent-1', ownerId == null ? 'UMKM Global' : 'Warung Owner'),
    ];
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
    statsOwnerIds.add(ownerId);
    return const DashboardStats(total: 7, verified: 4, pending: 2, rejected: 1);
  }
}

class _NoopStorageService implements StorageService {
  const _NoopStorageService();

  @override
  Future<String> uploadPhoto({
    required XFile file,
    required String umkmId,
  }) async {
    return '';
  }

  @override
  Future<void> deletePhotoByUrl(String publicUrl) async {}
}

class _FetchCall {
  const _FetchCall({required this.ownerId, required this.status});

  final String? ownerId;
  final String? status;
}

Umkm _umkm(String id, String name, {String status = 'verified'}) {
  final sampleDate = DateTime.utc(2026, 7, 9);
  return Umkm(
    id: id,
    ownerId: 'owner-1',
    namaUsaha: name,
    namaPemilik: 'Sari',
    kategoriId: 1,
    kategoriNama: 'Kuliner',
    deskripsi: 'Nasi campur.',
    alamatJalan: 'Jl. Merdeka',
    provinsiId: '51',
    provinsiNama: 'BALI',
    kotaId: '5171',
    kotaNama: 'KOTA DENPASAR',
    kecamatanId: '5171010',
    kecamatanNama: 'DENPASAR SELATAN',
    latitude: -8.7,
    longitude: 115.2,
    fotoUrl: null,
    status: status,
    createdAt: sampleDate,
    updatedAt: sampleDate,
  );
}
