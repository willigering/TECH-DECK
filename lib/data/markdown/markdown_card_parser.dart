import '../csv/csv_parser.dart';

abstract final class MarkdownCardParser {
  static CsvParseResult parseCards(String text) {
    final lines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final cards = <ParsedCardRow>[];
    String? question;
    final answer = StringBuffer();

    void commit() {
      final q = question?.trim() ?? '';
      final a = answer.toString().trim();
      if (q.isNotEmpty && a.isNotEmpty) {
        cards.add(ParsedCardRow(question: q, answer: a));
      }
      answer.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.startsWith('## ')) {
        if (question != null) commit();
        question = line.substring(3).trim();
      } else if (question != null) {
        if (answer.isNotEmpty) answer.writeln();
        answer.write(line);
      }
    }
    if (question != null) commit();

    return CsvParseResult(
      cards: cards,
      skipped: 0,
      delimiter: 'markdown',
    );
  }
}
