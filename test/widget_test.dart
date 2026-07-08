import 'package:flutter_test/flutter_test.dart';

import 'package:umkmap/main.dart';

void main() {
  testWidgets('shows UMKMap splash placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('UMKMap'), findsOneWidget);
    expect(find.text('Pendataan UMKM berbasis peta'), findsOneWidget);
  });
}
