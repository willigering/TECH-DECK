import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/ui/widgets/flip_card.dart';
import 'package:tech_deck/ui/widgets/pcb_background.dart';

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets(
      'Card reveals and resets answer, reduced motion: $reduceMotion',
      (tester) async {
        var flipped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: StatefulBuilder(
                builder: (context, setState) => Scaffold(
                  body: FlipStudyCard(
                    question: 'Question',
                    answer: 'Answer',
                    flipped: flipped,
                    onFlip: () => setState(() => flipped = !flipped),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Question'), findsOneWidget);
        await tester.tap(find.text('Question'));
        await tester.pumpAndSettle();
        expect(find.text('Answer'), findsOneWidget);
        await tester.tap(find.text('Answer'));
        await tester.pumpAndSettle();
        expect(find.text('Question'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Reduced motion background stays idle and allows taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: PcbBackground(
            child: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    await tester.tap(find.text('Tap'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
