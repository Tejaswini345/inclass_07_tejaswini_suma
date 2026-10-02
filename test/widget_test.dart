import 'package:digital_pet/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows pet, plays, disposes cleanly', (tester) async {
    await tester.pumpWidget(const DigitalPetApp());

    expect(find.textContaining('Okay'), findsOneWidget); // text mood label
    expect(find.text('Happiness'), findsOneWidget);

        await tester.ensureVisible(find.text('Play'));
    await tester.pump();
    await tester.tap(find.text('Play'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Play: Happiness +15'), findsOneWidget);

    // Leaving the screen disposes the controller (timers cancelled).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion still shows values and labels', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const DigitalPetApp());
    expect(find.text('Hunger'), findsOneWidget);
    expect(find.textContaining('Okay'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
