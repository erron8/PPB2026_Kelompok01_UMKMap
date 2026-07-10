import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/wilayah.dart';
import '../providers/auth_provider.dart';
import '../providers/umkm_provider.dart';
import '../utils/constants.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(title: const Text('Daftar UMKM')),
      floatingActionButton: canShowMine
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/umkm-form'),
              icon: const Icon(Icons.add_business),
              label: Text(
                'Tambah',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          _CategoryChips(
            provider: provider,
            onSelected: _selectCategory,
            onRetry: () =>
                context.read<UmkmProvider>().loadCategories(force: true),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: searchController,
              hintText: 'Cari nama usaha',
              leading: Icon(Icons.search, color: colorScheme.primary),
              trailing: searchController.text.isEmpty
                  ? null
                  : [
                      IconButton(
                        tooltip: 'Bersihkan pencarian',
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Color(AppColors.oliveGrey),
                        ),
                      ),
                    ],
              onChanged: onSearchChanged,
              onSubmitted: onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Filter wilayah',
            onPressed: onRegionPressed,
            style: IconButton.styleFrom(
              fixedSize: const Size.square(48),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.primary,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.tune),
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
      child: Container(
        height: 48,
        decoration: const ShapeDecoration(
          color: Color(AppColors.primaryContainer),
          shape: StadiumBorder(),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _SegmentedPillButton(
                label: 'Semua',
                selected: !showMine,
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: _SegmentedPillButton(
                label: 'UMKM Saya',
                selected: showMine,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedPillButton extends StatelessWidget {
  const _SegmentedPillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primary : Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: selected ? null : onTap,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onPrimaryContainer,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.provider,
    required this.onSelected,
    required this.onRetry,
  });

  final UmkmProvider provider;
  final ValueChanged<int?> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final categories = provider.categories;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    if (provider.categoryErrorMessage != null && categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _InlineRetryBanner(
          message: provider.categoryErrorMessage!,
          onRetry: onRetry,
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
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : const Color(AppColors.textMuted),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
            backgroundColor: colorScheme.surface,
            selectedColor: colorScheme.primary,
            side: selected
                ? BorderSide.none
                : const BorderSide(color: Color(AppColors.hairline)),
            shape: const StadiumBorder(),
            onSelected: (_) => onSelected(category?.id),
          );
        },
      ),
    );
  }
}

class _InlineRetryBanner extends StatelessWidget {
  const _InlineRetryBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: InputChip(
          avatar: Icon(
            Icons.location_city,
            size: 18,
            color: colorScheme.primary,
          ),
          label: Text(label, overflow: TextOverflow.ellipsis),
          labelStyle: const TextStyle(
            color: Color(AppColors.onSecondary),
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: const Color(AppColors.secondary),
          deleteIconColor: colorScheme.primary,
          side: BorderSide.none,
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
      return const _EmptyListState();
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
            onTap: () => context.push('/umkm/${umkm.id}'),
          );
        },
      ),
    );
  }
}

class _EmptyListState extends StatelessWidget {
  const _EmptyListState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront,
                color: colorScheme.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada UMKM',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba ubah pencarian atau filter wilayah.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(AppColors.textSubtle),
              ),
            ),
          ],
        ),
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
