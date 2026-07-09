import 'package:flutter_test/flutter_test.dart';
import 'package:umkmap/models/kategori.dart';
import 'package:umkmap/models/umkm.dart';
import 'package:umkmap/providers/umkm_provider.dart';
import 'package:umkmap/services/umkm_service.dart';

void main() {
  test('loadFirstPage and loadMore use 20-row pagination', () async {
    final service = _FakeUmkmService(
      pages: [
        List.generate(20, (index) => _umkm('u-$index')),
        List.generate(5, (index) => _umkm('u-${20 + index}')),
      ],
    );
    final provider = UmkmProvider(service: service);

    await provider.loadFirstPage();

    expect(provider.items, hasLength(20));
    expect(provider.hasMore, isTrue);
    expect(service.calls.single.page, 0);
    expect(service.calls.single.pageSize, 20);
    expect(service.calls.single.status, 'verified');

    await provider.loadMore();

    expect(provider.items, hasLength(25));
    expect(provider.hasMore, isFalse);
    expect(service.calls.last.page, 1);
  });

  test('filters are forwarded to fetchList', () async {
    final service = _FakeUmkmService(pages: [const []]);
    final provider = UmkmProvider(service: service)
      ..setSearchQuery('Warung')
      ..setKategoriFilter(1)
      ..setKotaFilter(
        id: '7371',
        nama: 'KOTA MAKASSAR',
        provinsiId: '73',
        provinsiNama: 'SULAWESI SELATAN',
      )
      ..setOwnerFilter('owner-1')
      ..setVerifiedOnly(false);

    await provider.loadFirstPage();

    final call = service.calls.single;
    expect(call.search, 'Warung');
    expect(call.kategoriId, 1);
    expect(call.kotaId, '7371');
    expect(call.ownerId, 'owner-1');
    expect(call.status, isNull);
  });

  test('setKotaFilter keeps province state for region preselection', () {
    final provider = UmkmProvider(service: _FakeUmkmService(pages: [const []]))
      ..setKotaFilter(
        id: '7371',
        nama: 'KOTA MAKASSAR',
        provinsiId: '73',
        provinsiNama: 'SULAWESI SELATAN',
      );

    expect(provider.provinsiId, '73');
    expect(provider.provinsiNama, 'SULAWESI SELATAN');
    expect(provider.kotaId, '7371');
    expect(provider.kotaNama, 'KOTA MAKASSAR');

    provider.setKotaFilter();

    expect(provider.provinsiId, isNull);
    expect(provider.provinsiNama, isNull);
    expect(provider.kotaId, isNull);
    expect(provider.kotaNama, isNull);
  });

  test('loadById reports inaccessible rows as detail error', () async {
    final service = _FakeUmkmService(pages: [const []], detail: null);
    final provider = UmkmProvider(service: service);

    await provider.loadById('missing-id');

    expect(provider.selectedUmkm, isNull);
    expect(
      provider.detailErrorMessage,
      'UMKM tidak ditemukan atau tidak dapat diakses.',
    );
  });
}

class _FakeUmkmService implements UmkmService {
  _FakeUmkmService({required this.pages, this.detail});

  final List<List<Umkm>> pages;
  final Umkm? detail;
  final List<_FetchCall> calls = [];

  @override
  Future<List<Kategori>> fetchKategori() async {
    return const [Kategori(id: 1, nama: 'Kuliner')];
  }

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
    calls.add(
      _FetchCall(
        search: search,
        kategoriId: kategoriId,
        kotaId: kotaId,
        ownerId: ownerId,
        status: status,
        page: page,
        pageSize: pageSize,
      ),
    );
    return page < pages.length ? pages[page] : const [];
  }

  @override
  Future<Umkm?> fetchById(String id) async => detail;

  @override
  Future<DashboardStats> dashboardStats({String? ownerId}) async {
    return const DashboardStats(total: 0, verified: 0, pending: 0, rejected: 0);
  }
}

class _FetchCall {
  const _FetchCall({
    required this.search,
    required this.kategoriId,
    required this.kotaId,
    required this.ownerId,
    required this.status,
    required this.page,
    required this.pageSize,
  });

  final String? search;
  final int? kategoriId;
  final String? kotaId;
  final String? ownerId;
  final String? status;
  final int page;
  final int pageSize;
}

Umkm _umkm(String id) {
  final sampleDate = DateTime.utc(2026, 7, 9);
  return Umkm(
    id: id,
    ownerId: 'owner-1',
    namaUsaha: 'Warung Bu Sari',
    namaPemilik: 'Sari',
    kategoriId: 1,
    kategoriNama: 'Kuliner',
    deskripsi: 'Nasi campur.',
    alamatJalan: 'Jl. Merdeka',
    provinsiId: '73',
    provinsiNama: 'SULAWESI SELATAN',
    kotaId: '7371',
    kotaNama: 'KOTA MAKASSAR',
    kecamatanId: '7371010',
    kecamatanNama: 'MAKASSAR',
    latitude: -5.1477,
    longitude: 119.4327,
    fotoUrl: null,
    status: 'verified',
    createdAt: sampleDate,
    updatedAt: sampleDate,
  );
}
