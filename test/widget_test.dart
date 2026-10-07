import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Sesuaikan 'vire' dengan field `name:` di pubspec.yaml kalau berbeda.
import 'package:vire/app.dart';

void main() {
  testWidgets('VireApp builds and shows the theme preview', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VireApp()));

    expect(find.text('Vire'), findsOneWidget);
  });
}