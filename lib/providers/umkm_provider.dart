import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../database/supabase_client.dart';
import '../models/kategori.dart';
import '../models/umkm.dart';
import '../models/umkm_report.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';
import '../services/umkm_service.dart';
import '../utils/app_exception.dart';

class UmkmProvider extends ChangeNotifier {
  UmkmProvider({
    UmkmService service = const UmkmService(),
    StorageService? storageService,
    ReportService reportService = const ReportService(),
  }) : _service = service,
       _storageService = storageService,
       _reportService = reportService;

  static const pageSize = 20;

  final UmkmService _service;
  final ReportService _reportService;
  StorageService? _storageService;

  StorageService get _storage => _storageService ??= StorageService();

  List<Umkm> items = [];
  List<Umkm> mapItems = [];
  List<Umkm> dashboardRecentItems = [];
  List<Umkm> pendingVerificationItems = [];
  List<Kategori> categories = [];
  List<UmkmReport> pendingReports = [];
  Umkm? selectedUmkm;
  DashboardStats? stats;

  bool isLoading = false;
  bool isLoadingMore = false;
  bool isLoadingCategories = false;
  bool isLoadingDetail = false;
  bool isLoadingStats = false;
  bool isLoadingDashboardRecent = false;
  bool isLoadingPendingVerification = false;
  bool isLoadingMapItems = false;
  bool isLoadingReports = false;
  bool isSubmitting = false;
  bool isSubmittingReport = false;
  bool isDeleting = false;
  bool isChangingStatus = false;
  bool hasMore = true;

  String? errorMessage;
  String? categoryErrorMessage;
  String? detailErrorMessage;
  String? statsErrorMessage;
  String? dashboardRecentErrorMessage;
  String? pendingVerificationErrorMessage;
  String? mapErrorMessage;
  String? reportsErrorMessage;
  String? mutationErrorMessage;
  String? reportMutationErrorMessage;

  String searchQuery = '';
  int? kategoriId;
  String? provinsiId;
  String? provinsiNama;
  String? kotaId;
  String? kotaNama;
  String? ownerId;
  bool verifiedOnly = true;

  int _page = 0;
  int _listRequestId = 0;
  int _detailRequestId = 0;
  int _mapRequestId = 0;

  Future<void> loadCategories({bool force = false}) async {
    if (categories.isNotEmpty && !force) return;

    isLoadingCategories = true;
    categoryErrorMessage = null;
    notifyListeners();

    try {
      categories = await _service.fetchKategori();
    } on AppException catch (error) {
      categoryErrorMessage = error.message;
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadFirstPage() async {
    final requestId = ++_listRequestId;
    _page = 0;
    hasMore = true;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final rows = await _service.fetchList(
        search: searchQuery,
        kategoriId: kategoriId,
        kotaId: kotaId,
        ownerId: ownerId,
        status: verifiedOnly ? 'verified' : null,
        page: _page,
        pageSize: pageSize,
      );
      if (requestId != _listRequestId) return;

      items = rows;
      hasMore = rows.length == pageSize;
    } on AppException catch (error) {
      if (requestId != _listRequestId) return;
      items = [];
      hasMore = false;
      errorMessage = error.message;
    } finally {
      if (requestId == _listRequestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;

    final nextPage = _page + 1;
    isLoadingMore = true;
    errorMessage = null;
    notifyListeners();

    try {
      final rows = await _service.fetchList(
        search: searchQuery,
        kategoriId: kategoriId,
        kotaId: kotaId,
        ownerId: ownerId,
        status: verifiedOnly ? 'verified' : null,
        page: nextPage,
        pageSize: pageSize,
      );

      _page = nextPage;
      items = [...items, ...rows];
      hasMore = rows.length == pageSize;
    } on AppException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadFirstPage();

  Future<void> loadById(String id) async {
    final requestId = ++_detailRequestId;
    selectedUmkm = null;
    detailErrorMessage = null;
    isLoadingDetail = true;
    notifyListeners();

    try {
      final row = await _service.fetchById(id);
      if (requestId != _detailRequestId) return;

      if (row == null) {
        detailErrorMessage = 'UMKM tidak ditemukan atau tidak dapat diakses.';
      } else {
        selectedUmkm = row;
      }
    } on AppException catch (error) {
      if (requestId != _detailRequestId) return;
      detailErrorMessage = error.message;
    } finally {
      if (requestId == _detailRequestId) {
        isLoadingDetail = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadDashboardStats({String? ownerId}) async {
    isLoadingStats = true;
    statsErrorMessage = null;
    notifyListeners();

    try {
      stats = await _service.dashboardStats(ownerId: ownerId);
    } on AppException catch (error) {
      statsErrorMessage = error.message;
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardRecent({String? ownerId}) async {
    isLoadingDashboardRecent = true;
    dashboardRecentErrorMessage = null;
    notifyListeners();

    try {
      dashboardRecentItems = await _service.fetchList(
        ownerId: ownerId,
        pageSize: 5,
      );
    } on AppException catch (error) {
      dashboardRecentItems = [];
      dashboardRecentErrorMessage = error.message;
    } finally {
      isLoadingDashboardRecent = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingVerification() async {
    isLoadingPendingVerification = true;
    pendingVerificationErrorMessage = null;
    notifyListeners();

    try {
      pendingVerificationItems = await _service.fetchList(
        status: 'pending',
        pageSize: 5,
      );
    } on AppException catch (error) {
      pendingVerificationItems = [];
      pendingVerificationErrorMessage = error.message;
    } finally {
      isLoadingPendingVerification = false;
      notifyListeners();
    }
  }

  Future<void> loadMapItems() async {
    final requestId = ++_mapRequestId;
    isLoadingMapItems = true;
    mapErrorMessage = null;
    notifyListeners();

    try {
      final rows = await _service.fetchList(status: 'verified', pageSize: 200);
      if (requestId != _mapRequestId) return;
      mapItems = rows;
    } on AppException catch (error) {
      if (requestId != _mapRequestId) return;
      mapItems = [];
      mapErrorMessage = error.message;
    } finally {
      if (requestId == _mapRequestId) {
        isLoadingMapItems = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>?> _uploadCategoryPhotos(String umkmId, Map<String, dynamic>? detailKategori) async {
    if (detailKategori == null) return null;
    
    final Map<String, dynamic> result = Map<String, dynamic>.from(detailKategori);
    final items = result['items'] as List?;
    if (items == null) return result;
    
    final updatedItems = [];
    for (int i = 0; i < items.length; i++) {
      final item = Map<String, dynamic>.from(items[i] as Map);
      final xfile = item['_foto_file'];
      if (xfile is XFile) {
        final path = 'kategori-details/$umkmId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await _storage.uploadCustomPath(file: xfile, path: path);
        item['foto_url'] = url;
      }
      item.remove('_foto_file');
      updatedItems.add(item);
    }
    result['items'] = updatedItems;
    return result;
  }

  Future<Umkm?> createUmkm({
    required UmkmInput input,
    required XFile photo,
  }) async {
    final id = _service.newId();
    String? uploadedPhotoUrl;

    _setSubmitting(true);
    try {
      uploadedPhotoUrl = await _storage.uploadPhoto(file: photo, umkmId: id);
      final finalDetailKategori = await _uploadCategoryPhotos(id, input.detailKategori);
      final created = await _service.create(
        id: id,
        input: input.withFotoUrl(uploadedPhotoUrl).withDetailKategori(finalDetailKategori),
      );
      selectedUmkm = created;
      _upsertItem(created);
      _upsertMapItem(created);
      _addCreatedToDashboard(created);
      mutationErrorMessage = null;
      return created;
    } on AppException catch (error) {
      mutationErrorMessage = error.message;
      await _deleteUploadedPhotoQuietly(uploadedPhotoUrl);
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<Umkm?> updateUmkm({
    required String id,
    required UmkmInput input,
    XFile? photo,
    String? previousPhotoUrl,
  }) async {
    String? uploadedPhotoUrl;

    _setSubmitting(true);
    try {
      if (photo != null) {
        uploadedPhotoUrl = await _storage.uploadPhoto(file: photo, umkmId: id);
      }
      final finalDetailKategori = await _uploadCategoryPhotos(id, input.detailKategori);
      final updated = await _service.update(
        id: id,
        input: input
            .withFotoUrl(uploadedPhotoUrl ?? input.fotoUrl)
            .withDetailKategori(finalDetailKategori),
      );
      selectedUmkm = updated;
      _upsertItem(updated);
      _upsertMapItem(updated);
      mutationErrorMessage = null;

      if (uploadedPhotoUrl != null &&
          previousPhotoUrl != null &&
          previousPhotoUrl.isNotEmpty &&
          previousPhotoUrl != uploadedPhotoUrl) {
        await _deleteUploadedPhotoQuietly(previousPhotoUrl);
      }

      return updated;
    } on AppException catch (error) {
      mutationErrorMessage = error.message;
      await _deleteUploadedPhotoQuietly(uploadedPhotoUrl);
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> deleteUmkm(String id) async {
    isDeleting = true;
    mutationErrorMessage = null;
    notifyListeners();

    try {
      await _service.delete(id);
      items = items.where((item) => item.id != id).toList(growable: false);
      mapItems = mapItems
          .where((item) => item.id != id)
          .toList(growable: false);
      if (selectedUmkm?.id == id) selectedUmkm = null;
      mutationErrorMessage = null;
      return true;
    } on AppException catch (error) {
      mutationErrorMessage = error.message;
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<Umkm?> setStatus({required String id, required String status}) async {
    isChangingStatus = true;
    mutationErrorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.setStatus(id: id, status: status);
      selectedUmkm = updated;
      _upsertItem(updated);
      _upsertMapItem(updated);
      mutationErrorMessage = null;
      unawaited(_refreshAdminDashboard());
      return updated;
    } on AppException catch (error) {
      mutationErrorMessage = error.message;
      return null;
    } finally {
      isChangingStatus = false;
      notifyListeners();
    }
  }

  Future<Umkm?> updateUmkmStatus(String umkmId, String statusBaru) {
    return setStatus(id: umkmId, status: statusBaru);
  }

  Future<void> _refreshAdminDashboard() async {
    await Future.wait([
      loadPendingVerification(),
      loadDashboardStats(ownerId: null),
      loadDashboardRecent(ownerId: null),
    ]);
  }

  void _addCreatedToDashboard(Umkm created) {
    dashboardRecentItems = [
      created,
      ...dashboardRecentItems,
    ].take(5).toList(growable: false);

    if (created.status == 'pending') {
      pendingVerificationItems = [
        created,
        ...pendingVerificationItems,
      ].take(5).toList(growable: false);
    }

    final current = stats;
    if (current != null) {
      stats = DashboardStats(
        total: current.total + 1,
        verified: current.verified + (created.status == 'verified' ? 1 : 0),
        pending: current.pending + (created.status == 'pending' ? 1 : 0),
        rejected: current.rejected + (created.status == 'rejected' ? 1 : 0),
      );
    }
  }

  void setSearchQuery(String value) {
    final trimmed = value.trim();
    if (searchQuery == trimmed) return;
    searchQuery = trimmed;
    notifyListeners();
  }

  void setKategoriFilter(int? value) {
    if (kategoriId == value) return;
    kategoriId = value;
    notifyListeners();
  }

  void setKotaFilter({
    String? id,
    String? nama,
    String? provinsiId,
    String? provinsiNama,
  }) {
    if (kotaId == id &&
        kotaNama == nama &&
        this.provinsiId == provinsiId &&
        this.provinsiNama == provinsiNama) {
      return;
    }
    this.provinsiId = id == null ? null : provinsiId;
    this.provinsiNama = id == null ? null : provinsiNama;
    kotaId = id;
    kotaNama = nama;
    notifyListeners();
  }

  void setOwnerFilter(String? value) {
    if (ownerId == value) return;
    ownerId = value;
    notifyListeners();
  }

  void setVerifiedOnly(bool value) {
    if (verifiedOnly == value) return;
    verifiedOnly = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    isSubmitting = value;
    if (value) mutationErrorMessage = null;
    notifyListeners();
  }

  void _upsertItem(Umkm value) {
    final index = items.indexWhere((item) => item.id == value.id);
    if (!_matchesActiveFilters(value)) {
      if (index >= 0) {
        items = [
          for (var i = 0; i < items.length; i++)
            if (i != index) items[i],
        ];
      }
      return;
    }

    if (index < 0) {
      items = [value, ...items];
    } else {
      items = [
        for (var i = 0; i < items.length; i++)
          if (i == index) value else items[i],
      ];
    }
  }

  void _upsertMapItem(Umkm value) {
    final index = mapItems.indexWhere((item) => item.id == value.id);
    if (value.status != 'verified') {
      if (index >= 0) {
        mapItems = [
          for (var i = 0; i < mapItems.length; i++)
            if (i != index) mapItems[i],
        ];
      }
      return;
    }

    if (index < 0) {
      mapItems = [value, ...mapItems];
    } else {
      mapItems = [
        for (var i = 0; i < mapItems.length; i++)
          if (i == index) value else mapItems[i],
      ];
    }
  }

  bool _matchesActiveFilters(Umkm value) {
    if (verifiedOnly && value.status != 'verified') return false;
    if (ownerId != null && ownerId!.isNotEmpty && value.ownerId != ownerId) {
      return false;
    }
    if (kategoriId != null && value.kategoriId != kategoriId) return false;
    if (kotaId != null && kotaId!.isNotEmpty && value.kotaId != kotaId) {
      return false;
    }
    if (searchQuery.isNotEmpty &&
        !value.namaUsaha.toLowerCase().contains(searchQuery.toLowerCase())) {
      return false;
    }
    return true;
  }

  Future<void> _deleteUploadedPhotoQuietly(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) return;
    try {
      await _storage.deletePhotoByUrl(photoUrl);
    } on AppException {
      // The row write outcome matters more than best-effort storage cleanup.
    }
  }

  Future<void> loadPendingReports() async {
    isLoadingReports = true;
    reportsErrorMessage = null;
    notifyListeners();

    try {
      try {
        final _ = AppSupabase.client;
      } catch (_) {
        // Supabase is not initialized (e.g., in unit tests)
        pendingReports = [];
        return;
      }
      pendingReports = await _reportService.fetchPendingReports();
    } on AppException catch (e) {
      reportsErrorMessage = e.message;
    } catch (e) {
      reportsErrorMessage = e.toString();
    } finally {
      isLoadingReports = false;
      notifyListeners();
    }
  }

  Future<bool> submitReport({
    required String umkmId,
    required String reporterId,
    required String tipeLaporan,
    required String deskripsi,
    required XFile fotoBukti,
  }) async {
    isSubmittingReport = true;
    reportMutationErrorMessage = null;
    notifyListeners();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'reports/$reporterId/$timestamp.jpg';
      final fotoUrl = await _storage.uploadCustomPath(file: fotoBukti, path: path);

      await _reportService.insertReport(
        umkmId: umkmId,
        reporterId: reporterId,
        tipeLaporan: tipeLaporan,
        deskripsi: deskripsi,
        fotoBuktiUrl: fotoUrl,
      );
      return true;
    } on AppException catch (e) {
      reportMutationErrorMessage = e.message;
      return false;
    } catch (e) {
      reportMutationErrorMessage = e.toString();
      return false;
    } finally {
      isSubmittingReport = false;
      notifyListeners();
    }
  }

  Future<bool> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    isChangingStatus = true;
    mutationErrorMessage = null;
    notifyListeners();

    try {
      await _reportService.updateReportStatus(reportId: reportId, status: status);
      pendingReports.removeWhere((r) => r.id == reportId);
      return true;
    } on AppException catch (e) {
      mutationErrorMessage = e.message;
      return false;
    } catch (e) {
      mutationErrorMessage = e.toString();
      return false;
    } finally {
      isChangingStatus = false;
      notifyListeners();
    }
  }
}
