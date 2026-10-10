import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Sesuaikan 'vire' dengan field `name:` di pubspec.yaml kalau berbeda.
import 'package:vire/app.dart';
import 'package:vire/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('VireApp shows V and animates to VIRE before navigation',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VireApp()));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<bool>(false)), findsOneWidget);
    expect(find.byKey(const ValueKey<bool>(true)), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 550));
    expect(find.byKey(const ValueKey<bool>(true)), findsOneWidget);
    expect(find.byKey(const ValueKey<bool>(false)), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
