import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/splash/presentation/splash_logo.dart';

void main() {
  testWidgets('V reaches its wordmark position before VIRE appears',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Center(child: SplashLogo()))));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    final moving = find.byKey(const ValueKey('splash-moving-v'));
    final wordmark = find.byKey(const ValueKey('splash-wordmark'));
    expect(tester.widget<Positioned>(moving).left, 34);
    expect(tester.widget<Opacity>(wordmark).opacity, 0);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 325));
    expect(tester.widget<Positioned>(moving).left, inExclusiveRange(0, 34));
    expect(tester.widget<Opacity>(wordmark).opacity, 0);
    await tester.pump(const Duration(milliseconds: 325));
    expect(tester.widget<Positioned>(moving).left, closeTo(0, 0.001));
    expect(tester.widget<Opacity>(wordmark).opacity, closeTo(0, 0.001));
    await tester.pump(const Duration(milliseconds: 110));
    expect(tester.widget<Opacity>(wordmark).opacity, inExclusiveRange(0, 1));
    expect(tester.widget<Positioned>(moving).left, 0);
    await tester.pump(const Duration(milliseconds: 110));
    expect(tester.widget<Opacity>(wordmark).opacity, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
