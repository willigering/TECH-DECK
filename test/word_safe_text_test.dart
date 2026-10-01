import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/ui/widgets/word_safe_text.dart';

void main() {
  testWidgets('German compounds have visible hyphens and keep their font size', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 140, child: WordSafeText(
        text: 'Datenschutzbeauftragten', style: TextStyle(fontSize: 26),
      )),
    ))));
    final rendered = tester.widget<Text>(find.descendant(
      of: find.byType(WordSafeText), matching: find.byType(Text),
    ));
    expect(rendered.style!.fontSize, 26);
    expect(rendered.data, contains('-\n'));
    expect(rendered.data!.replaceAll('-\n', ''), 'Datenschutzbeauftragten');
    expect(rendered.softWrap, isFalse);
    expect(find.byType(FittedBox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
