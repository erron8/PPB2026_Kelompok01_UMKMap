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

  bool _detailsInitialized = false;

  final List<_KulinerItemInput> _kulinerItems = [];
  final List<_JasaItemInput> _jasaItems = [];
  final List<_FashionItemInput> _fashionItems = [];
  final List<_KerajinanItemInput> _kerajinanItems = [];
  final List<_PertanianItemInput> _pertanianItems = [];
  final List<_LainnyaItemInput> _lainnyaItems = [];

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
    final categories = provider.categories;

    if (!_detailsInitialized && widget.initialUmkm != null && categories.isNotEmpty) {
      _initializeCategoryDetails(categories);
      _detailsInitialized = true;
    }

    final String catName = _getCategoryName(_selectedKategoriId, categories);
    Widget? dynamicSection;
    if (catName.toLowerCase() == 'kuliner') {
      dynamicSection = _buildKulinerForm();
    } else if (catName.toLowerCase() == 'jasa') {
      dynamicSection = _buildJasaForm();
    } else if (catName.toLowerCase() == 'fashion') {
      dynamicSection = _buildFashionForm();
    } else if (catName.toLowerCase() == 'kerajinan') {
      dynamicSection = _buildKerajinanForm();
    } else if (catName.toLowerCase() == 'pertanian') {
      dynamicSection = _buildPertanianForm();
    } else if (catName.toLowerCase() == 'lainnya') {
      dynamicSection = _buildLainnyaForm();
    }

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
                    if (dynamicSection != null) ...[
                      const SizedBox(height: 12),
                      _FormSectionCard(
                        title: 'Detail Spesifik Kategori ($catName)',
                        children: [
                          dynamicSection,
                        ],
                      ),
                    ],
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

    final provider = context.read<UmkmProvider>();
    final categories = provider.categories;
    final catName = _getCategoryName(_selectedKategoriId, categories).toLowerCase();

    Map<String, dynamic>? detailKategori;
    if (catName == 'kuliner') {
      detailKategori = {
        'items': _kulinerItems.map((it) => {
          'nama': it.nama.trim(),
          'harga': it.harga,
          'foto_url': it.isPhotoRemoved ? null : it.fotoUrl,
          '_foto_file': it.fotoFile,
        }).toList()
      };
    } else if (catName == 'jasa') {
      detailKategori = {
        'items': _jasaItems.map((it) => {
          'nama': it.nama.trim(),
          'harga_mulai': it.hargaMulai,
          'deskripsi': it.deskripsi.trim(),
        }).toList()
      };
    } else if (catName == 'fashion') {
      detailKategori = {
        'items': _fashionItems.map((it) => {
          'nama': it.nama.trim(),
          'harga': it.harga,
          'ukuran': it.ukuran,
          'foto_url': it.isPhotoRemoved ? null : it.fotoUrl,
          '_foto_file': it.fotoFile,
        }).toList()
      };
    } else if (catName == 'kerajinan') {
      detailKategori = {
        'items': _kerajinanItems.map((it) => {
          'nama': it.nama.trim(),
          'harga': it.harga,
          'bahan': it.bahan.trim(),
          'foto_url': it.isPhotoRemoved ? null : it.fotoUrl,
          '_foto_file': it.fotoFile,
        }).toList()
      };
    } else if (catName == 'pertanian') {
      detailKategori = {
        'items': _pertanianItems.map((it) => {
          'nama': it.nama.trim(),
          'harga': it.harga,
          'panen': it.panen.trim(),
          'deskripsi': it.deskripsi.trim(),
        }).toList()
      };
    } else if (catName == 'lainnya') {
      detailKategori = {
        'items': _lainnyaItems.map((it) => {
          'key': it.key.trim(),
          'value': it.value.trim(),
        }).toList()
      };
    }

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
      detailKategori: detailKategori,
    );

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

  String _getCategoryName(int? id, List<Kategori> categories) {
    if (id == null) return '';
    final cat = categories.firstWhere(
      (c) => c.id == id,
      orElse: () => const Kategori(id: -1, nama: ''),
    );
    if (cat.id != -1) return cat.nama;
    return widget.initialUmkm?.kategoriNama ?? '';
  }

  void _initializeCategoryDetails(List<Kategori> categories) {
    final detail = widget.initialUmkm?.detailKategori;
    if (detail == null) return;
    
    final catName = _getCategoryName(widget.initialUmkm?.kategoriId, categories).toLowerCase();
    
    setState(() {
      if (catName == 'kuliner') {
        final items = detail['items'] as List?;
        if (items != null) {
          _kulinerItems.clear();
          for (final it in items) {
            final map = it as Map<String, dynamic>;
            _kulinerItems.add(_KulinerItemInput(
              nama: map['nama'] as String? ?? '',
              harga: map['harga'] as int? ?? 0,
              fotoUrl: map['foto_url'] as String?,
            ));
          }
        }
      } else if (catName == 'jasa') {
        final items = detail['items'] as List?;
        if (items != null) {
          _jasaItems.clear();
          for (final it in items) {
            final map = it as Map<String, dynamic>;
            _jasaItems.add(_JasaItemInput(
              nama: map['nama'] as String? ?? '',
              hargaMulai: map['harga_mulai'] as int? ?? 0,
              deskripsi: map['deskripsi'] as String? ?? '',
            ));
          }
        }
      } else if (catName == 'fashion') {
        final items = detail['items'] as List?;
        if (items != null) {
          _fashionItems.clear();
          for (final it in items) {
            final map = it as Map<String, dynamic>;
            _fashionItems.add(_FashionItemInput(
              nama: map['nama'] as String? ?? '',
              harga: map['harga'] as int? ?? 0,
              ukuran: List<String>.from(map['ukuran'] as List? ?? []),
              fotoUrl: map['foto_url'] as String?,
            ));
          }
        }
      } else if (catName == 'kerajinan') {
        final items = detail['items'] as List?;
        if (items != null) {
          _kerajinanItems.clear();
          for (final it in items) {
            final map = it as Map<String, dynamic>;
            _kerajinanItems.add(_KerajinanItemInput(
              nama: map['nama'] as String? ?? '',
              harga: map['harga'] as int? ?? 0,
              bahan: map['bahan'] as String? ?? '',
              fotoUrl: map['foto_url'] as String?,
            ));
          }
        }
      } else if (catName == 'pertanian') {
        final items = detail['items'] as List?;
        if (items != null) {
          _pertanianItems.clear();
          for (final it in items) {
            final map = it as Map<String, dynamic>;
            _pertanianItems.add(_PertanianItemInput(
              nama: map['nama'] as String? ?? '',
              harga: map['harga'] as int? ?? 0,
              panen: map['panen'] as String? ?? '',
              deskripsi: map['deskripsi'] as String? ?? '',
            ));
          }
        }
      } else if (catName == 'lainnya') {
        final items = detail['items'] as List?;
        if (items != null) {
          _lainnyaItems.clear();
          for (final it in items) {
            final map = it as Map<String, dynamic>;
            _lainnyaItems.add(_LainnyaItemInput(
              key: map['key'] as String? ?? '',
              value: map['value'] as String? ?? '',
            ));
          }
        }
      }
    });
  }

  Widget _buildKulinerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_kulinerItems.length, (index) {
          final item = _kulinerItems[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(AppColors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Menu #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(AppColors.error)),
                        onPressed: () => setState(() => _kulinerItems.removeAt(index)),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: item.nama,
                    decoration: const InputDecoration(labelText: 'Nama Makanan/Minuman'),
                    onChanged: (val) => item.nama = val,
                    validator: (val) => Validators.requiredText(val, 'Nama menu'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.harga > 0 ? item.harga.toString() : '',
                    decoration: const InputDecoration(labelText: 'Harga (Rupiah)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => item.harga = int.tryParse(val) ?? 0,
                    validator: (val) => Validators.requiredText(val, 'Harga menu'),
                  ),
                  const SizedBox(height: 12),
                  PhotoPickerField(
                    label: 'Foto Makanan/Minuman',
                    selectedFile: item.fotoFile,
                    photoUrl: item.isPhotoRemoved ? null : item.fotoUrl,
                    onChanged: (file) {
                      setState(() {
                        item.fotoFile = file;
                        if (file != null) item.isPhotoRemoved = false;
                      });
                    },
                    onRemoved: () {
                      setState(() {
                        item.isPhotoRemoved = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() => _kulinerItems.add(_KulinerItemInput())),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Menu Andalan'),
        ),
      ],
    );
  }

  Widget _buildJasaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_jasaItems.length, (index) {
          final item = _jasaItems[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(AppColors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Jasa/Layanan #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(AppColors.error)),
                        onPressed: () => setState(() => _jasaItems.removeAt(index)),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: item.nama,
                    decoration: const InputDecoration(labelText: 'Nama Jasa/Layanan'),
                    onChanged: (val) => item.nama = val,
                    validator: (val) => Validators.requiredText(val, 'Nama layanan'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.hargaMulai > 0 ? item.hargaMulai.toString() : '',
                    decoration: const InputDecoration(labelText: 'Estimasi Harga Mulai (Rupiah)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => item.hargaMulai = int.tryParse(val) ?? 0,
                    validator: (val) => Validators.requiredText(val, 'Harga mulai'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.deskripsi,
                    decoration: const InputDecoration(labelText: 'Deskripsi Singkat Jasa'),
                    maxLines: 2,
                    onChanged: (val) => item.deskripsi = val,
                  ),
                ],
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() => _jasaItems.add(_JasaItemInput())),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Layanan Jasa'),
        ),
      ],
    );
  }

  Widget _buildFashionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_fashionItems.length, (index) {
          final item = _fashionItems[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(AppColors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Produk Fashion #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(AppColors.error)),
                        onPressed: () => setState(() => _fashionItems.removeAt(index)),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: item.nama,
                    decoration: const InputDecoration(labelText: 'Nama Produk'),
                    onChanged: (val) => item.nama = val,
                    validator: (val) => Validators.requiredText(val, 'Nama produk'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.harga > 0 ? item.harga.toString() : '',
                    decoration: const InputDecoration(labelText: 'Harga (Rupiah)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => item.harga = int.tryParse(val) ?? 0,
                    validator: (val) => Validators.requiredText(val, 'Harga produk'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pilihan Ukuran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: ['S', 'M', 'L', 'XL', 'XXL'].map((size) {
                      final isSelected = item.ukuran.contains(size);
                      return FilterChip(
                        label: Text(size),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              item.ukuran.add(size);
                            } else {
                              item.ukuran.remove(size);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  PhotoPickerField(
                    label: 'Foto Produk',
                    selectedFile: item.fotoFile,
                    photoUrl: item.isPhotoRemoved ? null : item.fotoUrl,
                    onChanged: (file) {
                      setState(() {
                        item.fotoFile = file;
                        if (file != null) item.isPhotoRemoved = false;
                      });
                    },
                    onRemoved: () {
                      setState(() {
                        item.isPhotoRemoved = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() => _fashionItems.add(_FashionItemInput())),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Produk Fashion'),
        ),
      ],
    );
  }

  Widget _buildKerajinanForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_kerajinanItems.length, (index) {
          final item = _kerajinanItems[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(AppColors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kerajinan #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(AppColors.error)),
                        onPressed: () => setState(() => _kerajinanItems.removeAt(index)),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: item.nama,
                    decoration: const InputDecoration(labelText: 'Nama Produk Kerajinan'),
                    onChanged: (val) => item.nama = val,
                    validator: (val) => Validators.requiredText(val, 'Nama produk'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.harga > 0 ? item.harga.toString() : '',
                    decoration: const InputDecoration(labelText: 'Harga (Rupiah)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => item.harga = int.tryParse(val) ?? 0,
                    validator: (val) => Validators.requiredText(val, 'Harga produk'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.bahan,
                    decoration: const InputDecoration(labelText: 'Bahan Utama'),
                    onChanged: (val) => item.bahan = val,
                    validator: (val) => Validators.requiredText(val, 'Bahan utama'),
                  ),
                  const SizedBox(height: 12),
                  PhotoPickerField(
                    label: 'Foto Kerajinan',
                    selectedFile: item.fotoFile,
                    photoUrl: item.isPhotoRemoved ? null : item.fotoUrl,
                    onChanged: (file) {
                      setState(() {
                        item.fotoFile = file;
                        if (file != null) item.isPhotoRemoved = false;
                      });
                    },
                    onRemoved: () {
                      setState(() {
                        item.isPhotoRemoved = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() => _kerajinanItems.add(_KerajinanItemInput())),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Produk Kerajinan'),
        ),
      ],
    );
  }

  Widget _buildPertanianForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_pertanianItems.length, (index) {
          final item = _pertanianItems[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(AppColors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hasil Pertanian #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(AppColors.error)),
                        onPressed: () => setState(() => _pertanianItems.removeAt(index)),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: item.nama,
                    decoration: const InputDecoration(labelText: 'Nama Hasil Pertanian'),
                    onChanged: (val) => item.nama = val,
                    validator: (val) => Validators.requiredText(val, 'Nama hasil tani'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.harga > 0 ? item.harga.toString() : '',
                    decoration: const InputDecoration(labelText: 'Harga per Satuan (Rupiah)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => item.harga = int.tryParse(val) ?? 0,
                    validator: (val) => Validators.requiredText(val, 'Harga satuan'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.panen,
                    decoration: const InputDecoration(labelText: 'Musim Panen'),
                    onChanged: (val) => item.panen = val,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.deskripsi,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    maxLines: 2,
                    onChanged: (val) => item.deskripsi = val,
                  ),
                ],
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() => _pertanianItems.add(_PertanianItemInput())),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Hasil Pertanian'),
        ),
      ],
    );
  }

  Widget _buildLainnyaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_lainnyaItems.length, (index) {
          final item = _lainnyaItems[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(AppColors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Atribut #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(AppColors.error)),
                        onPressed: () => setState(() => _lainnyaItems.removeAt(index)),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: item.key,
                    decoration: const InputDecoration(labelText: 'Nama Field (Key)'),
                    onChanged: (val) => item.key = val,
                    validator: (val) => Validators.requiredText(val, 'Nama field'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: item.value,
                    decoration: const InputDecoration(labelText: 'Isi Field (Value)'),
                    onChanged: (val) => item.value = val,
                    validator: (val) => Validators.requiredText(val, 'Isi field'),
                  ),
                ],
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() => _lainnyaItems.add(_LainnyaItemInput())),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Atribut Kustom'),
        ),
      ],
    );
  }
}

class _KulinerItemInput {
  _KulinerItemInput({this.nama = '', this.harga = 0, this.fotoUrl});
  String nama;
  int harga;
  String? fotoUrl;
  XFile? fotoFile;
  bool isPhotoRemoved = false;
}

class _JasaItemInput {
  _JasaItemInput({this.nama = '', this.hargaMulai = 0, this.deskripsi = ''});
  String nama;
  int hargaMulai;
  String deskripsi;
}

class _FashionItemInput {
  _FashionItemInput({this.nama = '', this.harga = 0, List<String>? ukuran, this.fotoUrl})
      : ukuran = ukuran ?? [];
  String nama;
  int harga;
  List<String> ukuran;
  String? fotoUrl;
  XFile? fotoFile;
  bool isPhotoRemoved = false;
}

class _KerajinanItemInput {
  _KerajinanItemInput({this.nama = '', this.harga = 0, this.bahan = '', this.fotoUrl});
  String nama;
  int harga;
  String bahan;
  String? fotoUrl;
  XFile? fotoFile;
  bool isPhotoRemoved = false;
}

class _PertanianItemInput {
  _PertanianItemInput({this.nama = '', this.harga = 0, this.panen = '', this.deskripsi = ''});
  String nama;
  int harga;
  String panen;
  String deskripsi;
}

class _LainnyaItemInput {
  _LainnyaItemInput({this.key = '', this.value = ''});
  String key;
  String value;
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
