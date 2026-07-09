import 'package:flutter/foundation.dart';

import '../models/kategori.dart';
import '../models/umkm.dart';
import '../services/umkm_service.dart';
import '../utils/app_exception.dart';

class UmkmProvider extends ChangeNotifier {
  UmkmProvider({UmkmService service = const UmkmService()})
    : _service = service;

  static const pageSize = 20;

  final UmkmService _service;

  List<Umkm> items = [];
  List<Kategori> categories = [];
  Umkm? selectedUmkm;
  DashboardStats? stats;

  bool isLoading = false;
  bool isLoadingMore = false;
  bool isLoadingCategories = false;
  bool isLoadingDetail = false;
  bool isLoadingStats = false;
  bool hasMore = true;

  String? errorMessage;
  String? categoryErrorMessage;
  String? detailErrorMessage;
  String? statsErrorMessage;

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
}
