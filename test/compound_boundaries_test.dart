import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/ui/widgets/word_safe_text.dart';

void main() {
  test('Prefer compound boundaries over syllable boundaries', () {
    expect(WordSafeText.preferredBreaks('Datenschutzbehörde'), [5, 11]);
    expect(WordSafeText.preferredBreaks('Datenschutzbeauftragte'), [5, 11]);
    expect(WordSafeText.preferredBreaks('Datenschutzbeauftragten'), [5, 11]);
    expect(WordSafeText.preferredBreaks('Netzwerkverbindung'), [8]);
    expect(WordSafeText.preferredBreaks('Datenbanken'), [5]);
    expect(WordSafeText.preferredBreaks('Netzwerken'), isEmpty);
  });
}
