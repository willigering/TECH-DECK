import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/data/csv/csv_parser.dart';

void main() {
  test('exact pairs preserve command flags, case and field boundaries', () {
    expect(CsvParser.cardKey('ls -a', 'A'), isNot(CsvParser.cardKey('ls -A', 'A')));
    expect(CsvParser.cardKey('a||b', 'c'), isNot(CsvParser.cardKey('a', 'b||c')));
    expect(CsvParser.cardKey(' Q ', ' A '), CsvParser.cardKey('Q', 'A'));
  });
  test('rejects an incomplete recognized header', () {
    expect(
      () => CsvParser.parseCards('Frage;AnswerTypo\nDNS?;Names'),
      throwsFormatException,
    );
  });
  test('rejects unclosed quotes instead of discarding the rest', () {
    expect(
      () => CsvParser.parseCards('Frage;Antwort\n"DNS?;Names'),
      throwsFormatException,
    );
  });
  test('preserves multiline fields, escaped quotes and headerless files', () {
    final parsed = CsvParser.parseCards(
      'Frage;Antwort\n"DNS?";"Zeile 1\nZeile ""2"""',
    );
    expect(parsed.cards.single.answer, 'Zeile 1\nZeile "2"');
    expect(CsvParser.parseCards('DNS?;Names').cards.single.question, 'DNS?');
  });
}
