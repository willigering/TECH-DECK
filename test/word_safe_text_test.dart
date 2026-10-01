import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/ui/widgets/word_safe_text.dart';

void main() {
  testWidgets('Long compound words remain intact at narrow widths', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 140, child: WordSafeText(
        text: 'Der Datenschutzbeauftragten',
        style: TextStyle(fontSize: 26),
      )),
    ))));
    final text = tester.widget<Text>(find.text('Datenschutzbeauftragten '));
    expect(text.softWrap, isFalse);
    expect(tester.getSize(find.byType(WordSafeText)).width, 140);
    expect(tester.takeException(), isNull);
  });
}
