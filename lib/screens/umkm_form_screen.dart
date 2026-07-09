import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/kategori.dart';
import '../models/umkm.dart';
import '../models/wilayah.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/umkm_provider.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
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

  late LatLng _initialMapPoint;
  int? _selectedKategoriId;
  Wilayah? _selectedProvince;
  Wilayah? _selectedRegency;
  Wilayah? _selectedDistrict;
  LatLng? _selectedPoint;
  bool _userMovedPin = false;
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
      if (!_isEditMode) _prefillCurrentLocation();
    });
  }

  // Create mode: drop the pin on the device's current location so a new UMKM
  // is not silently saved at the region default center. If GPS is
  // denied/unavailable, keep the default center and let the user place the pin
  // manually (map tap/drag or "Gunakan Lokasi Saya").
  Future<void> _prefillCurrentLocation() async {
    try {
      final point = await context.read<LocationProvider>().loadCurrentPoint();
      if (!mounted || _userMovedPin) return;
      setState(() {
        _initialMapPoint = point;
        _selectedPoint = point;
      });
    } on AppException {
      // Keep the region default center; manual placement remains available.
    }
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
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _FormSectionCard(
                      title: 'Foto & Identitas',
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
                        const SizedBox(height: 12),
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
                          onRetry: () => context
                              .read<UmkmProvider>()
                              .loadCategories(force: true),
                          onChanged: (value) {
                            setState(() => _selectedKategoriId = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FormSectionCard(
                      title: 'Deskripsi & Alamat',
                      children: [
                        AppTextField(
                          controller: _deskripsiController,
                          label: 'Deskripsi',
                          minLines: 3,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _alamatJalanController,
                          label: 'Alamat Jalan',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        WilayahDropdowns(
                          initialProvinceId: widget.initialUmkm?.provinsiId,
                          initialRegencyId: widget.initialUmkm?.kotaId,
                          initialDistrictId: widget.initialUmkm?.kecamatanId,
                          provinceValidator: (value) =>
                              Validators.requiredSelection(value, 'Provinsi'),
                          regencyValidator: (value) =>
                              Validators.requiredSelection(
                                value,
                                'Kota/kabupaten',
                              ),
                          districtValidator: (value) =>
                              Validators.requiredSelection(value, 'Kecamatan'),
                          onChanged: ({province, regency, district}) {
                            _selectedProvince = province;
                            _selectedRegency = regency;
                            _selectedDistrict = district;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FormSectionCard(
                      title: 'Lokasi di Peta',
                      children: [
                        MapCoordinatePicker(
                          initialLatitude: _initialMapPoint.latitude,
                          initialLongitude: _initialMapPoint.longitude,
                          enabled: !isSubmitting,
                          currentLocationLoader: () => context
                              .read<LocationProvider>()
                              .loadCurrentPoint(),
                          errorText: _coordinateErrorText,
                          onChanged: (point) {
                            setState(() {
                              _userMovedPin = true;
                              _selectedPoint = point;
                              _coordinateErrorText = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _SubmitBar(
                isSubmitting: isSubmitting,
                label: _isEditMode ? 'Simpan Perubahan' : 'Simpan UMKM',
                errorMessage: provider.mutationErrorMessage,
                onSubmit: _submit,
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

    final router = GoRouter.of(context);
    final bool? goToDetail;
    if (initialUmkm == null) {
      goToDetail = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 28,
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text('UMKM Tersimpan'),
            ],
          ),
          content: Text(
            _successMessage(initialUmkm: initialUmkm, saved: saved),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Kembali ke Beranda'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lihat Detail'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    } else {
      _showSnackBar(_successMessage(initialUmkm: initialUmkm, saved: saved));
      goToDetail = true;
    }

    router.go('/dashboard');
    if (goToDetail == true) {
      router.push('/umkm/${saved.id}');
    }
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

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(AppColors.textPrimary),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isSubmitting,
    required this.label,
    required this.errorMessage,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final String label;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(AppColors.surface),
        border: Border(top: BorderSide(color: Color(AppColors.hairline))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (errorMessage != null && !isSubmitting) ...[
                _InlineRetry(message: errorMessage!, onRetry: onSubmit),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: label,
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
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
      decoration: const InputDecoration(labelText: 'Kategori'),
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
      decoration: InputDecoration(labelText: label),
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
        color: const Color(AppColors.statusRejectedFill),
        borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
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
