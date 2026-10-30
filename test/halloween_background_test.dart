import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/ui/widgets/halloween_background.dart';

void main() {
  test('Halloween is limited to October 24–31, every year', () {
    expect(isHalloweenSeason(DateTime(2026, 10, 23)), isFalse);
    expect(isHalloweenSeason(DateTime(2026, 10, 24)), isTrue);
    expect(isHalloweenSeason(DateTime(2026, 10, 31, 23, 59)), isTrue);
    expect(isHalloweenSeason(DateTime(2026, 11, 1)), isFalse);
    expect(isHalloweenSeason(DateTime(2027, 10, 31)), isTrue);
  });

  testWidgets('Decoration preserves child geometry and taps', (tester) async {
    var taps = 0;
    final key = GlobalKey();
    Future<void> show(DateTime date) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 500,
              child: HalloweenBackground(
                now: () => date,
                child: Center(
                  child: TextButton(
                    key: key,
                    onPressed: () => taps++,
                    child: const Text('Lernen'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(DateTime(2026, 10, 23));
    final before = tester.getRect(find.byKey(key));
    await show(DateTime(2026, 10, 31));
    expect(tester.getRect(find.byKey(key)), before);
    await tester.tap(find.text('Lernen'));
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
