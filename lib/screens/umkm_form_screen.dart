import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/kategori.dart';
import '../models/umkm.dart';
import '../models/wilayah.dart';
import '../providers/auth_provider.dart';
import '../providers/umkm_provider.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/map_coordinate_picker.dart';
import '../widgets/photo_picker_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/wilayah_dropdowns.dart';

class UmkmFormScreen extends StatefulWidget {
  const UmkmFormScreen({super.key, this.initialUmkm});

  final Umkm? initialUmkm;

  @override
  State<UmkmFormScreen> createState() => _UmkmFormScreenState();
}

class _UmkmFormScreenState extends State<UmkmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaUsahaController = TextEditingController();
  final _namaPemilikController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _alamatJalanController = TextEditingController();

  late final LatLng _initialMapPoint;
  int? _selectedKategoriId;
  Wilayah? _selectedProvince;
  Wilayah? _selectedRegency;
  Wilayah? _selectedDistrict;
  LatLng? _selectedPoint;
  XFile? _selectedPhoto;
  bool _existingPhotoRemoved = false;
  String? _photoErrorText;
  String? _coordinateErrorText;

  bool get _isEditMode => widget.initialUmkm != null;

  @override
  void initState() {
    super.initState();
    final initialUmkm = widget.initialUmkm;
    if (initialUmkm != null) {
      _namaUsahaController.text = initialUmkm.namaUsaha;
      _namaPemilikController.text = initialUmkm.namaPemilik;
      _deskripsiController.text = initialUmkm.deskripsi ?? '';
      _alamatJalanController.text = initialUmkm.alamatJalan ?? '';
      _selectedKategoriId = initialUmkm.kategoriId;
      _selectedProvince = Wilayah(
        id: initialUmkm.provinsiId,
        name: initialUmkm.provinsiNama,
      );
      _selectedRegency = Wilayah(
        id: initialUmkm.kotaId,
        name: initialUmkm.kotaNama,
      );
      _selectedDistrict = Wilayah(
        id: initialUmkm.kecamatanId,
        name: initialUmkm.kecamatanNama,
      );
      _selectedPoint = LatLng(initialUmkm.latitude, initialUmkm.longitude);
    } else {
      _selectedPoint = MapCoordinatePicker.defaultCenter;
    }
    _initialMapPoint = _selectedPoint!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UmkmProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _namaUsahaController.dispose();
    _namaPemilikController.dispose();
    _deskripsiController.dispose();
    _alamatJalanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UmkmProvider>();
    final isSubmitting = provider.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit UMKM' : 'Tambah UMKM')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              PhotoPickerField(
                selectedFile: _selectedPhoto,
                photoUrl: _existingPhotoRemoved
                    ? null
                    : widget.initialUmkm?.fotoUrl,
                enabled: !isSubmitting,
                onChanged: (file) {
                  setState(() {
                    _selectedPhoto = file;
                    if (file != null) _existingPhotoRemoved = false;
                    _photoErrorText = null;
                  });
                },
                onRemoved: () {
                  setState(() {
                    _existingPhotoRemoved = true;
                    _photoErrorText = null;
                  });
                },
              ),
              if (_photoErrorText != null) ...[
                const SizedBox(height: 6),
                _FieldErrorText(_photoErrorText!),
              ],
              const SizedBox(height: 16),
              AppTextField(
                controller: _namaUsahaController,
                label: 'Nama Usaha',
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.requiredText(value, 'Nama usaha'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _namaPemilikController,
                label: 'Nama Pemilik',
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.requiredText(value, 'Nama pemilik'),
              ),
              const SizedBox(height: 12),
              _CategoryDropdown(
                categories: provider.categories,
                selectedId: _selectedKategoriId,
                isLoading: provider.isLoadingCategories,
                errorMessage: provider.categoryErrorMessage,
                enabled: !isSubmitting,
                onRetry: () =>
                    context.read<UmkmProvider>().loadCategories(force: true),
                onChanged: (value) {
                  setState(() => _selectedKategoriId = value);
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _alamatJalanController,
                label: 'Alamat Jalan',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _deskripsiController,
                label: 'Deskripsi',
                minLines: 3,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),
              WilayahDropdowns(
                initialProvinceId: widget.initialUmkm?.provinsiId,
                initialRegencyId: widget.initialUmkm?.kotaId,
                initialDistrictId: widget.initialUmkm?.kecamatanId,
                provinceValidator: (value) =>
                    Validators.requiredSelection(value, 'Provinsi'),
                regencyValidator: (value) =>
                    Validators.requiredSelection(value, 'Kota/kabupaten'),
                districtValidator: (value) =>
                    Validators.requiredSelection(value, 'Kecamatan'),
                onChanged: ({province, regency, district}) {
                  _selectedProvince = province;
                  _selectedRegency = regency;
                  _selectedDistrict = district;
                },
              ),
              const SizedBox(height: 16),
              MapCoordinatePicker(
                initialLatitude: _initialMapPoint.latitude,
                initialLongitude: _initialMapPoint.longitude,
                enabled: !isSubmitting,
                errorText: _coordinateErrorText,
                onChanged: (point) {
                  setState(() {
                    _selectedPoint = point;
                    _coordinateErrorText = null;
                  });
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditMode ? 'Simpan Perubahan' : 'Simpan UMKM',
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState?.validate() ?? false;
    final photoError = _validatePhoto();
    final coordinateError = _selectedPoint == null
        ? 'Koordinat lokasi wajib dipilih.'
        : null;

    setState(() {
      _photoErrorText = photoError;
      _coordinateErrorText = coordinateError;
    });

    if (!formValid || photoError != null || coordinateError != null) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      _showSnackBar('Silakan masuk untuk menyimpan data UMKM.');
      context.go('/login');
      return;
    }

    final initialUmkm = widget.initialUmkm;
    final ownerId = initialUmkm?.ownerId ?? user.id;
    final existingPhotoUrl = _existingPhotoRemoved
        ? null
        : initialUmkm?.fotoUrl;
    final input = UmkmInput(
      ownerId: ownerId,
      namaUsaha: _namaUsahaController.text.trim(),
      namaPemilik: _namaPemilikController.text.trim(),
      kategoriId: _selectedKategoriId!,
      deskripsi: _emptyToNull(_deskripsiController.text),
      alamatJalan: _emptyToNull(_alamatJalanController.text),
      provinsiId: _selectedProvince!.id,
      provinsiNama: _selectedProvince!.name,
      kotaId: _selectedRegency!.id,
      kotaNama: _selectedRegency!.name,
      kecamatanId: _selectedDistrict!.id,
      kecamatanNama: _selectedDistrict!.name,
      latitude: _selectedPoint!.latitude,
      longitude: _selectedPoint!.longitude,
      fotoUrl: existingPhotoUrl,
    );

    final provider = context.read<UmkmProvider>();
    final saved = initialUmkm == null
        ? await provider.createUmkm(input: input, photo: _selectedPhoto!)
        : await provider.updateUmkm(
            id: initialUmkm.id,
            input: input,
            photo: _selectedPhoto,
            previousPhotoUrl: initialUmkm.fotoUrl,
          );

    if (!mounted) return;

    if (saved == null) {
      _showSnackBar(provider.mutationErrorMessage ?? 'Gagal menyimpan UMKM.');
      return;
    }

    _showSnackBar(_successMessage(initialUmkm: initialUmkm, saved: saved));
    context.go('/umkm/${saved.id}');
  }

  String _successMessage({required Umkm? initialUmkm, required Umkm saved}) {
    if (initialUmkm == null) {
      return 'UMKM tersimpan dan menunggu verifikasi.';
    }
    if (initialUmkm.status != 'pending' && saved.status == 'pending') {
      return 'Perubahan UMKM tersimpan dan menunggu verifikasi ulang.';
    }
    return 'Perubahan UMKM tersimpan.';
  }

  String? _validatePhoto() {
    final hasExistingPhoto =
        !_existingPhotoRemoved &&
        widget.initialUmkm?.fotoUrl != null &&
        widget.initialUmkm!.fotoUrl!.isNotEmpty;
    if (_selectedPhoto == null && !hasExistingPhoto) {
      return 'Foto UMKM wajib ditambahkan.';
    }
    return null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    required this.isLoading,
    required this.errorMessage,
    required this.enabled,
    required this.onRetry,
    required this.onChanged,
  });

  final List<Kategori> categories;
  final int? selectedId;
  final bool isLoading;
  final String? errorMessage;
  final bool enabled;
  final VoidCallback onRetry;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isLoading && categories.isEmpty) {
      return const _LoadingField(label: 'Kategori');
    }

    if (errorMessage != null && categories.isEmpty) {
      return _InlineRetry(message: errorMessage!, onRetry: onRetry);
    }

    return DropdownButtonFormField<int>(
      initialValue: _hasSelectedCategory ? selectedId : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih kategori'),
      validator: (value) => Validators.requiredSelection(value, 'Kategori'),
      items: categories
          .map(
            (category) => DropdownMenuItem<int>(
              value: category.id,
              child: Text(category.nama, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
    );
  }

  bool get _hasSelectedCategory {
    if (selectedId == null) return false;
    return categories.any((category) => category.id == selectedId);
  }
}

class _LoadingField extends StatelessWidget {
  const _LoadingField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: const Row(
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Memuat data...'),
        ],
      ),
    );
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.message, required this.onRetry});

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

class _FieldErrorText extends StatelessWidget {
  const _FieldErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
