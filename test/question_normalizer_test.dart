import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/logic/question_normalizer.dart';

void main() {
  test('identische Fragen unabhängig von Groß/Klein und Leerzeichen', () {
    expect(
      QuestionNormalizer.areDuplicates('Was ist DHCP?', '  was ist dhcp ? '),
      isTrue,
    );
  });

  test('gleicher Kern bei unterschiedlicher Formulierung', () {
    expect(
      QuestionNormalizer.areDuplicates('Was ist DHCP?', 'Was bedeutet DHCP?'),
      isTrue,
    );
    expect(
      QuestionNormalizer.areDuplicates('Was ist DHCP?', 'Erkläre DHCP.'),
      isTrue,
    );
  });

  test('fachlich unterschiedliche Fragen bleiben getrennt', () {
    expect(
      QuestionNormalizer.areDuplicates('Was ist DHCP?', 'Was ist DNS?'),
      isFalse,
    );
    expect(
      QuestionNormalizer.areDuplicates(
        'Was ist TCP?',
        'Was ist der Unterschied zwischen TCP und UDP?',
      ),
      isFalse,
    );
  });

  test('Fingerprint entfernt Fragesätze', () {
    expect(QuestionNormalizer.fingerprint('Was ist DHCP?'), 'dhcp');
    expect(QuestionNormalizer.fingerprint('Was bedeutet DHCP?'), 'dhcp');
    expect(QuestionNormalizer.fingerprint('Erkläre DHCP.'), 'dhcp');
  });
}
