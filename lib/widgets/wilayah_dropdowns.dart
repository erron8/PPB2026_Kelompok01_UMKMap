import 'package:flutter/material.dart';

import '../models/wilayah.dart';
import '../services/wilayah_api_service.dart';

typedef WilayahSelectionChanged =
    void Function({Wilayah? province, Wilayah? regency, Wilayah? district});

class WilayahDropdowns extends StatefulWidget {
  const WilayahDropdowns({
    super.key,
    this.service,
    this.initialProvinceId,
    this.initialRegencyId,
    this.initialDistrictId,
    this.onChanged,
    this.provinceValidator,
    this.regencyValidator,
    this.districtValidator,
  });

  final WilayahApiService? service;
  final String? initialProvinceId;
  final String? initialRegencyId;
  final String? initialDistrictId;
  final WilayahSelectionChanged? onChanged;
  final FormFieldValidator<Wilayah>? provinceValidator;
  final FormFieldValidator<Wilayah>? regencyValidator;
  final FormFieldValidator<Wilayah>? districtValidator;

  @override
  State<WilayahDropdowns> createState() => _WilayahDropdownsState();
}

enum _LoadTarget { provinces, regencies, districts }

class _WilayahDropdownsState extends State<WilayahDropdowns> {
  late WilayahApiService _service;

  List<Wilayah> _provinces = [];
  List<Wilayah> _regencies = [];
  List<Wilayah> _districts = [];

  Wilayah? _selectedProvince;
  Wilayah? _selectedRegency;
  Wilayah? _selectedDistrict;

  bool _loadingProvinces = false;
  bool _loadingRegencies = false;
  bool _loadingDistricts = false;

  String? _errorMessage;
  _LoadTarget? _lastFailedLoad;
  String? _lastFailedParentId;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? WilayahApiService();
    _loadProvinces(useInitialSelection: true);
  }

  @override
  void didUpdateWidget(covariant WilayahDropdowns oldWidget) {
    super.didUpdateWidget(oldWidget);

    final initialSelectionChanged =
        oldWidget.initialProvinceId != widget.initialProvinceId ||
        oldWidget.initialRegencyId != widget.initialRegencyId ||
        oldWidget.initialDistrictId != widget.initialDistrictId;
    if (oldWidget.service != widget.service || initialSelectionChanged) {
      _service = widget.service ?? WilayahApiService();
      _resetSelections();
      _loadProvinces(useInitialSelection: true);
    }
  }

  Future<void> _loadProvinces({bool useInitialSelection = false}) async {
    setState(() {
      _loadingProvinces = true;
      _errorMessage = null;
      _lastFailedLoad = null;
      _lastFailedParentId = null;
    });

    try {
      final provinces = await _service.provinces();
      if (!mounted) return;

      final selectedProvince = useInitialSelection
          ? _findById(provinces, widget.initialProvinceId)
          : _selectedProvince;

      setState(() {
        _provinces = provinces;
        _selectedProvince = selectedProvince;
        _loadingProvinces = false;
      });

      if (selectedProvince != null) {
        await _loadRegencies(
          selectedProvince.id,
          useInitialSelection: useInitialSelection,
        );
      } else {
        _notifyChanged();
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingProvinces = false;
        _errorMessage = 'Gagal memuat provinsi.';
        _lastFailedLoad = _LoadTarget.provinces;
      });
    }
  }

  Future<void> _loadRegencies(
    String provinceId, {
    bool useInitialSelection = false,
  }) async {
    setState(() {
      _loadingRegencies = true;
      _errorMessage = null;
      _lastFailedLoad = null;
      _lastFailedParentId = null;
    });

    try {
      final regencies = await _service.regencies(provinceId);
      if (!mounted) return;

      final selectedRegency = useInitialSelection
          ? _findById(regencies, widget.initialRegencyId)
          : _selectedRegency;

      setState(() {
        _regencies = regencies;
        _selectedRegency = selectedRegency;
        _loadingRegencies = false;
      });

      if (selectedRegency != null) {
        await _loadDistricts(
          selectedRegency.id,
          useInitialSelection: useInitialSelection,
        );
      } else {
        _notifyChanged();
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingRegencies = false;
        _errorMessage = 'Gagal memuat kota/kabupaten.';
        _lastFailedLoad = _LoadTarget.regencies;
        _lastFailedParentId = provinceId;
      });
    }
  }

  Future<void> _loadDistricts(
    String regencyId, {
    bool useInitialSelection = false,
  }) async {
    setState(() {
      _loadingDistricts = true;
      _errorMessage = null;
      _lastFailedLoad = null;
      _lastFailedParentId = null;
    });

    try {
      final districts = await _service.districts(regencyId);
      if (!mounted) return;

      setState(() {
        _districts = districts;
        _selectedDistrict = useInitialSelection
            ? _findById(districts, widget.initialDistrictId)
            : _selectedDistrict;
        _loadingDistricts = false;
      });
      _notifyChanged();
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingDistricts = false;
        _errorMessage = 'Gagal memuat kecamatan.';
        _lastFailedLoad = _LoadTarget.districts;
        _lastFailedParentId = regencyId;
      });
    }
  }

  void _onProvinceChanged(Wilayah? province) {
    setState(() {
      _selectedProvince = province;
      _selectedRegency = null;
      _selectedDistrict = null;
      _regencies = [];
      _districts = [];
      _errorMessage = null;
    });
    _notifyChanged();

    if (province != null) {
      _loadRegencies(province.id);
    }
  }

  void _onRegencyChanged(Wilayah? regency) {
    setState(() {
      _selectedRegency = regency;
      _selectedDistrict = null;
      _districts = [];
      _errorMessage = null;
    });
    _notifyChanged();

    if (regency != null) {
      _loadDistricts(regency.id);
    }
  }

  void _onDistrictChanged(Wilayah? district) {
    setState(() {
      _selectedDistrict = district;
      _errorMessage = null;
    });
    _notifyChanged();
  }

  void _retry() {
    switch (_lastFailedLoad) {
      case _LoadTarget.provinces:
        _loadProvinces(useInitialSelection: true);
        break;
      case _LoadTarget.regencies:
        final provinceId = _lastFailedParentId ?? _selectedProvince?.id;
        if (provinceId != null) _loadRegencies(provinceId);
        break;
      case _LoadTarget.districts:
        final regencyId = _lastFailedParentId ?? _selectedRegency?.id;
        if (regencyId != null) _loadDistricts(regencyId);
        break;
      case null:
        break;
    }
  }

  void _resetSelections() {
    _provinces = [];
    _regencies = [];
    _districts = [];
    _selectedProvince = null;
    _selectedRegency = null;
    _selectedDistrict = null;
    _errorMessage = null;
    _lastFailedLoad = null;
    _lastFailedParentId = null;
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      province: _selectedProvince,
      regency: _selectedRegency,
      district: _selectedDistrict,
    );
  }

  Wilayah? _findById(List<Wilayah> items, String? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WilayahDropdownField(
          fieldKey: const ValueKey('wilayah_province_dropdown'),
          label: 'Provinsi',
          hint: _loadingProvinces ? 'Memuat provinsi...' : 'Pilih provinsi',
          value: _selectedProvince,
          items: _provinces,
          isLoading: _loadingProvinces,
          onChanged: _loadingProvinces ? null : _onProvinceChanged,
          validator: widget.provinceValidator,
        ),
        const SizedBox(height: 12),
        _WilayahDropdownField(
          fieldKey: const ValueKey('wilayah_regency_dropdown'),
          label: 'Kota/Kabupaten',
          hint: _regencyHint,
          value: _selectedRegency,
          items: _regencies,
          isLoading: _loadingRegencies,
          onChanged: _selectedProvince == null || _loadingRegencies
              ? null
              : _onRegencyChanged,
          validator: widget.regencyValidator,
        ),
        const SizedBox(height: 12),
        _WilayahDropdownField(
          fieldKey: const ValueKey('wilayah_district_dropdown'),
          label: 'Kecamatan',
          hint: _districtHint,
          value: _selectedDistrict,
          items: _districts,
          isLoading: _loadingDistricts,
          onChanged: _selectedRegency == null || _loadingDistricts
              ? null
              : _onDistrictChanged,
          validator: widget.districtValidator,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _WilayahErrorState(message: _errorMessage!, onRetry: _retry),
        ],
      ],
    );
  }

  String get _regencyHint {
    if (_selectedProvince == null) return 'Pilih provinsi dahulu';
    if (_loadingRegencies) return 'Memuat kota/kabupaten...';
    return 'Pilih kota/kabupaten';
  }

  String get _districtHint {
    if (_selectedRegency == null) return 'Pilih kota/kabupaten dahulu';
    if (_loadingDistricts) return 'Memuat kecamatan...';
    return 'Pilih kecamatan';
  }
}

class _WilayahDropdownField extends StatelessWidget {
  const _WilayahDropdownField({
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.isLoading,
    required this.onChanged,
    this.validator,
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final Wilayah? value;
  final List<Wilayah> items;
  final bool isLoading;
  final ValueChanged<Wilayah?>? onChanged;
  final FormFieldValidator<Wilayah>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Wilayah>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      hint: Text(hint),
      items: items
          .map(
            (item) => DropdownMenuItem<Wilayah>(
              value: item,
              child: Text(item.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _WilayahErrorState extends StatelessWidget {
  const _WilayahErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: colorScheme.error)),
            ),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
