import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:umkmap/models/kategori.dart';
import 'package:umkmap/models/umkm.dart';
import 'package:umkmap/providers/umkm_provider.dart';
import 'package:umkmap/services/storage_service.dart';
import 'package:umkmap/services/umkm_service.dart';
import 'package:umkmap/utils/app_exception.dart';

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

  test('createUmkm uploads photo and inserts row with generated id', () async {
    final service = _FakeUmkmService(pages: [const []]);
    final storage = _FakeStorageService();
    final provider = UmkmProvider(service: service, storageService: storage)
      ..setOwnerFilter('owner-1')
      ..setVerifiedOnly(false);
    final input = _input();

    final created = await provider.createUmkm(
      input: input,
      photo: XFile('/tmp/warung.jpg'),
    );

    expect(created, isNotNull);
    expect(created!.id, service.generatedId);
    expect(created.status, 'pending');
    expect(created.fotoUrl, storage.uploadedUrl);
    expect(service.createdInput?.fotoUrl, storage.uploadedUrl);
    expect(storage.uploadedUmkmIds, [service.generatedId]);
    expect(provider.items.single.id, service.generatedId);
  });

  test('createUmkm deletes uploaded photo when insert fails', () async {
    final service = _FakeUmkmService(pages: [const []], failCreate: true);
    final storage = _FakeStorageService();
    final provider = UmkmProvider(service: service, storageService: storage);

    final created = await provider.createUmkm(
      input: _input(),
      photo: XFile('/tmp/warung.jpg'),
    );

    expect(created, isNull);
    expect(provider.mutationErrorMessage, 'insert failed');
    expect(storage.deletedUrls, [storage.uploadedUrl]);
  });

  test('deleteUmkm removes row from provider list', () async {
    final row = _umkm('delete-me');
    final service = _FakeUmkmService(
      pages: [
        [row],
      ],
    );
    final provider = UmkmProvider(
      service: service,
      storageService: _FakeStorageService(),
    );

    await provider.loadFirstPage();
    final deleted = await provider.deleteUmkm(row.id);

    expect(deleted, isTrue);
    expect(service.deletedIds, [row.id]);
    expect(provider.items, isEmpty);
  });

  test('setStatus updates selected item and list item', () async {
    final row = _umkm('verify-me').copyWith(status: 'pending');
    final service = _FakeUmkmService(
      pages: [
        [row],
      ],
      detail: row,
    );
    final provider = UmkmProvider(
      service: service,
      storageService: _FakeStorageService(),
    );

    await provider.loadFirstPage();
    final updated = await provider.setStatus(id: row.id, status: 'verified');

    expect(updated?.status, 'verified');
    expect(provider.selectedUmkm?.status, 'verified');
    expect(provider.items.single.status, 'verified');
    expect(service.statusCalls, [('verify-me', 'verified')]);
  });
}

class _FakeUmkmService implements UmkmService {
  _FakeUmkmService({required this.pages, this.detail, this.failCreate = false});

  final List<List<Umkm>> pages;
  final Umkm? detail;
  final bool failCreate;
  final String generatedId = '00000000-0000-4000-8000-000000000001';
  final List<_FetchCall> calls = [];
  final List<String> deletedIds = [];
  final List<(String, String)> statusCalls = [];
  UmkmInput? createdInput;
  UmkmInput? updatedInput;

  @override
  String newId() => generatedId;

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
  Future<Umkm> create({required String id, required UmkmInput input}) async {
    if (failCreate) throw const AppException('insert failed');
    createdInput = input;
    return _umkmFromInput(id, input, status: 'pending');
  }

  @override
  Future<Umkm> update({required String id, required UmkmInput input}) async {
    updatedInput = input;
    return _umkmFromInput(id, input, status: 'pending');
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<Umkm> setStatus({required String id, required String status}) async {
    statusCalls.add((id, status));
    final base =
        detail ??
        pages
            .expand((page) => page)
            .firstWhere((item) => item.id == id, orElse: () => _umkm(id));
    return base.copyWith(status: status);
  }

  @override
  Future<DashboardStats> dashboardStats({String? ownerId}) async {
    return const DashboardStats(total: 0, verified: 0, pending: 0, rejected: 0);
  }
}

class _FakeStorageService implements StorageService {
  final uploadedUrl = 'https://example.test/storage/warung.jpg';
  final List<String> uploadedUmkmIds = [];
  final List<String> deletedUrls = [];

  @override
  Future<String> uploadPhoto({
    required XFile file,
    required String umkmId,
  }) async {
    uploadedUmkmIds.add(umkmId);
    return uploadedUrl;
  }

  @override
  Future<void> deletePhotoByUrl(String publicUrl) async {
    deletedUrls.add(publicUrl);
  }

  @override
  Future<String> uploadCustomPath({
    required XFile file,
    required String path,
  }) async {
    return 'https://example.test/storage/$path';
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

UmkmInput _input() {
  return const UmkmInput(
    ownerId: 'owner-1',
    namaUsaha: 'Warung Bu Sari',
    namaPemilik: 'Sari',
    kategoriId: 1,
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
  );
}

Umkm _umkmFromInput(String id, UmkmInput input, {required String status}) {
  final sampleDate = DateTime.utc(2026, 7, 9);
  return Umkm(
    id: id,
    ownerId: input.ownerId,
    namaUsaha: input.namaUsaha,
    namaPemilik: input.namaPemilik,
    kategoriId: input.kategoriId,
    kategoriNama: 'Kuliner',
    deskripsi: input.deskripsi,
    alamatJalan: input.alamatJalan,
    provinsiId: input.provinsiId,
    provinsiNama: input.provinsiNama,
    kotaId: input.kotaId,
    kotaNama: input.kotaNama,
    kecamatanId: input.kecamatanId,
    kecamatanNama: input.kecamatanNama,
    latitude: input.latitude,
    longitude: input.longitude,
    fotoUrl: input.fotoUrl,
    status: status,
    createdAt: sampleDate,
    updatedAt: sampleDate,
  );
}
