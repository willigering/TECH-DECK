import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/ui/screens/privacy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Privacy policy is bundled with developer and contact', () async {
    final policy = await rootBundle.loadString('assets/legal/privacy_de.txt');
    expect(policy, contains('Willi Gering'));
    expect(policy, contains('info@geringdigital.de'));
    expect(policy, contains('GitHub'));
    expect(policy, contains('Löschung'));
  });

  testWidgets('Policy can be read without a network connection', (
    tester,
  ) async {
    await tester.runAsync(
      () => rootBundle.loadString('assets/legal/privacy_de.txt'),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
    });
    await tester.pumpAndSettle();
    expect(find.text('Datenschutzerklärung'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.textContaining('info@geringdigital.de'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
