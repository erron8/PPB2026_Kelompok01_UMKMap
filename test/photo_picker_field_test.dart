import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:umkmap/widgets/photo_picker_field.dart';

void main() {
  testWidgets('shows camera permission dialog when camera access is denied', (
    tester,
  ) async {
    var didChange = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotoPickerField(
            onChanged: (_) => didChange = true,
            pickPhoto: (source) async {
              expect(source, ImageSource.camera);
              throw PlatformException(code: 'camera_access_denied');
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('photo_picker_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();

    expect(
      find.text('Izin kamera diperlukan untuk mengambil foto'),
      findsOneWidget,
    );
    expect(find.text('Buka Pengaturan'), findsOneWidget);
    expect(didChange, isFalse);
  });
}
