import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

typedef PickPhoto = Future<XFile?> Function(ImageSource source);

class PhotoPickerField extends StatefulWidget {
  const PhotoPickerField({
    super.key,
    required this.onChanged,
    this.selectedFile,
    this.photoUrl,
    this.onRemoved,
    this.pickPhoto,
    this.enabled = true,
    this.label = 'Foto UMKM',
  });

  final ValueChanged<XFile?> onChanged;
  final XFile? selectedFile;
  final String? photoUrl;
  final VoidCallback? onRemoved;
  final PickPhoto? pickPhoto;
  final bool enabled;
  final String label;

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.selectedFile;
  }

  @override
  void didUpdateWidget(covariant PhotoPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFile?.path != widget.selectedFile?.path) {
      _selectedFile = widget.selectedFile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        _selectedFile != null ||
        (widget.photoUrl != null && widget.photoUrl!.isNotEmpty);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          key: const ValueKey('photo_picker_field'),
          onTap: widget.enabled ? _showSourceSheet : null,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surface,
            ),
            child: SizedBox(
              height: 184,
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: _PhotoPreview(
                            file: _selectedFile,
                            photoUrl: widget.photoUrl,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filledTonal(
                            key: const ValueKey('photo_remove_button'),
                            tooltip: 'Hapus Foto',
                            onPressed: widget.enabled ? _removePhoto : null,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ],
                    )
                  : const _EmptyPhotoState(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Dari Galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await _pickPhoto(source);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = widget.pickPhoto != null
          ? await widget.pickPhoto!(source)
          : await _picker.pickImage(
              source: source,
              maxWidth: 1280,
              maxHeight: 1280,
              requestFullMetadata: false,
            );

      if (!mounted || picked == null) return;
      setState(() => _selectedFile = picked);
      widget.onChanged(picked);
    } on PlatformException catch (error) {
      if (!mounted) return;
      if (_isPermissionError(error)) {
        await _showPermissionDialog(source);
        return;
      }
      _showSnackBar('Gagal mengambil foto. Coba lagi.');
    }
  }

  bool _isPermissionError(PlatformException error) {
    final code = error.code.toLowerCase();
    return code.contains('denied') || code.contains('restricted');
  }

  Future<void> _showPermissionDialog(ImageSource source) async {
    final message = source == ImageSource.camera
        ? 'Izin kamera diperlukan untuk mengambil foto'
        : 'Izin galeri diperlukan untuk memilih foto';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  void _removePhoto() {
    setState(() => _selectedFile = null);
    widget.onChanged(null);
    widget.onRemoved?.call();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.file, required this.photoUrl});

  final XFile? file;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (file != null) {
      return Image.file(File(file!.path), fit: BoxFit.cover);
    }

    return Image.network(
      photoUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const _EmptyPhotoState(message: 'Foto tidak dapat dimuat');
      },
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  const _EmptyPhotoState({this.message = 'Tambah Foto'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 36,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}
