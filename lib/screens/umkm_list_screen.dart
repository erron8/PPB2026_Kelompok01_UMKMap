import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/wilayah.dart';
import '../providers/auth_provider.dart';
import '../providers/umkm_provider.dart';
import '../widgets/loading_and_error.dart';
import '../widgets/umkm_card.dart';
import '../widgets/wilayah_dropdowns.dart';

class UmkmListScreen extends StatefulWidget {
  const UmkmListScreen({super.key});

  @override
  State<UmkmListScreen> createState() => _UmkmListScreenState();
}

class _UmkmListScreenState extends State<UmkmListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showMine = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_initialized) return;
    _initialized = true;

    final provider = context.read<UmkmProvider>();
    final auth = context.read<AuthProvider>();
    _applyTabFilters(provider, auth);
    await Future.wait([provider.loadCategories(), provider.loadFirstPage()]);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter < 360) {
      context.read<UmkmProvider>().loadMore();
    }
  }

  void _applyTabFilters(UmkmProvider provider, AuthProvider auth) {
    final userId = auth.user?.id;
    final canShowMine =
        auth.status == AuthStatus.authenticated && userId != null;
    if (_showMine && canShowMine) {
      provider
        ..setOwnerFilter(userId)
        ..setVerifiedOnly(false);
    } else {
      _showMine = false;
      provider
        ..setOwnerFilter(null)
        ..setVerifiedOnly(true);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<UmkmProvider>()
        ..setSearchQuery(value)
        ..loadFirstPage();
    });
  }

  Future<void> _selectCategory(int? id) async {
    final provider = context.read<UmkmProvider>()..setKategoriFilter(id);
    await provider.loadFirstPage();
  }

  Future<void> _switchTab(bool showMine) async {
    setState(() => _showMine = showMine);
    final provider = context.read<UmkmProvider>();
    final auth = context.read<AuthProvider>();
    _applyTabFilters(provider, auth);
    await provider.loadFirstPage();
  }

  Future<void> _openRegionFilter() async {
    final provider = context.read<UmkmProvider>();
    final selected = await showModalBottomSheet<_RegionSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RegionFilterSheet(
        initialProvinsiId: provider.provinsiId,
        initialProvinsiNama: provider.provinsiNama,
        initialKotaId: provider.kotaId,
        initialKotaNama: provider.kotaNama,
      ),
    );

    if (!mounted || selected == null) return;
    provider
      ..setKotaFilter(
        id: selected.id,
        nama: selected.name,
        provinsiId: selected.provinceId,
        provinsiNama: selected.provinceName,
      )
      ..loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<UmkmProvider>();
    final canShowMine = auth.status == AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar UMKM')),
      floatingActionButton: canShowMine
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/umkm-form'),
              icon: const Icon(Icons.add_business),
              label: const Text('Tambah'),
            )
          : null,
      body: Column(
        children: [
          _SearchAndFilters(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onRegionPressed: _openRegionFilter,
          ),
          if (canShowMine)
            _ListModeTabs(showMine: _showMine, onChanged: _switchTab),
          _CategoryChips(provider: provider, onSelected: _selectCategory),
          if (provider.kotaNama != null)
            _ActiveRegionFilter(
              label: provider.kotaNama!,
              onClear: () {
                context.read<UmkmProvider>()
                  ..setKotaFilter()
                  ..loadFirstPage();
              },
            ),
          Expanded(child: _ListBody(controller: _scrollController)),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.searchController,
    required this.onSearchChanged,
    required this.onRegionPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRegionPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: searchController,
              hintText: 'Cari nama usaha',
              leading: const Icon(Icons.search),
              trailing: searchController.text.isEmpty
                  ? null
                  : [
                      IconButton(
                        tooltip: 'Bersihkan pencarian',
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
              onChanged: onSearchChanged,
              onSubmitted: onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Filter wilayah',
            onPressed: onRegionPressed,
            icon: const Icon(Icons.location_city),
          ),
        ],
      ),
    );
  }
}

class _ListModeTabs extends StatelessWidget {
  const _ListModeTabs({required this.showMine, required this.onChanged});

  final bool showMine;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.storefront),
              label: Text('Direktori'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.inventory_2_outlined),
              label: Text('UMKM Saya'),
            ),
          ],
          selected: {showMine},
          onSelectionChanged: (values) => onChanged(values.first),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.provider, required this.onSelected});

  final UmkmProvider provider;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = provider.categories;

    if (provider.isLoadingCategories && categories.isEmpty) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categories[index - 1];
          final selected = isAll
              ? provider.kategoriId == null
              : provider.kategoriId == category!.id;

          return ChoiceChip(
            label: Text(isAll ? 'Semua' : category!.nama),
            selected: selected,
            onSelected: (_) => onSelected(category?.id),
          );
        },
      ),
    );
  }
}

class _ActiveRegionFilter extends StatelessWidget {
  const _ActiveRegionFilter({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: InputChip(
          avatar: const Icon(Icons.location_city, size: 18),
          label: Text(label, overflow: TextOverflow.ellipsis),
          onDeleted: onClear,
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UmkmProvider>();

    if (provider.isLoading && provider.items.isEmpty) {
      return const LoadingAndError(isLoading: true);
    }
    if (provider.errorMessage != null && provider.items.isEmpty) {
      return LoadingAndError(
        errorMessage: provider.errorMessage,
        onRetry: provider.loadFirstPage,
      );
    }
    if (provider.items.isEmpty) {
      return const LoadingAndError(
        emptyMessage: 'Belum ada UMKM yang sesuai dengan filter.',
        icon: Icons.search_off,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: provider.items.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.items.length) {
            return _ListFooter(provider: provider);
          }

          final umkm = provider.items[index];
          return UmkmCard(
            umkm: umkm,
            onTap: () => context.go('/umkm/${umkm.id}'),
          );
        },
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.provider});

  final UmkmProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: provider.loadMore,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Lagi'),
          ),
        ),
      );
    }

    if (!provider.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Semua data sudah dimuat',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return const SizedBox(height: 16);
  }
}

class _RegionFilterSheet extends StatefulWidget {
  const _RegionFilterSheet({
    this.initialProvinsiId,
    this.initialProvinsiNama,
    this.initialKotaId,
    this.initialKotaNama,
  });

  final String? initialProvinsiId;
  final String? initialProvinsiNama;
  final String? initialKotaId;
  final String? initialKotaNama;

  @override
  State<_RegionFilterSheet> createState() => _RegionFilterSheetState();
}

class _RegionFilterSheetState extends State<_RegionFilterSheet> {
  Wilayah? _selectedProvince;
  Wilayah? _selectedRegency;

  @override
  void initState() {
    super.initState();

    final initialKotaId = widget.initialKotaId;
    final initialProvinsiId = _initialProvinceId;
    if (initialProvinsiId != null && initialProvinsiId.isNotEmpty) {
      _selectedProvince = Wilayah(
        id: initialProvinsiId,
        name: widget.initialProvinsiNama ?? initialProvinsiId,
      );
    }
    if (initialKotaId != null && initialKotaId.isNotEmpty) {
      _selectedRegency = Wilayah(
        id: initialKotaId,
        name: widget.initialKotaNama ?? initialKotaId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filter Wilayah', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          WilayahDropdowns(
            initialProvinceId: _initialProvinceId,
            initialRegencyId: widget.initialKotaId,
            onChanged: ({province, regency, district}) {
              setState(() {
                _selectedProvince = province;
                _selectedRegency = regency;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const _RegionSelection(id: null, name: null)),
                child: const Text('Hapus Filter'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _selectedRegency == null
                    ? null
                    : () => Navigator.of(context).pop(
                        _RegionSelection(
                          id: _selectedRegency!.id,
                          name: _selectedRegency!.name,
                          provinceId: _selectedProvince?.id,
                          provinceName: _selectedProvince?.name,
                        ),
                      ),
                icon: const Icon(Icons.check),
                label: const Text('Terapkan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? get _initialProvinceId {
    final explicitId = widget.initialProvinsiId;
    if (explicitId != null && explicitId.isNotEmpty) return explicitId;

    final regencyId = widget.initialKotaId;
    if (regencyId == null || regencyId.length < 2) return null;
    return regencyId.substring(0, 2);
  }
}

class _RegionSelection {
  const _RegionSelection({
    required this.id,
    required this.name,
    this.provinceId,
    this.provinceName,
  });

  final String? id;
  final String? name;
  final String? provinceId;
  final String? provinceName;
}
