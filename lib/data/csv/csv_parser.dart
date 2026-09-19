import 'dart:convert';

/// Robustes CSV-Parsing: UTF-8/BOM, Quotes, Delimiter-Erkennung, Umlaute.
class CsvDocument {
  const CsvDocument({
    required this.headers,
    required this.rows,
    required this.delimiter,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final String delimiter;
}

class ParsedCardRow {
  const ParsedCardRow({
    required this.question,
    required this.answer,
    this.wrongAnswer1 = '',
    this.wrongAnswer2 = '',
    this.wrongAnswer3 = '',
  });

  final String question;
  final String answer;
  final String wrongAnswer1;
  final String wrongAnswer2;
  final String wrongAnswer3;

  List<String> get wrongAnswers => [wrongAnswer1, wrongAnswer2, wrongAnswer3];
}

class CsvParseResult {
  const CsvParseResult({
    required this.cards,
    required this.skipped,
    required this.delimiter,
    this.skippedEmptyQuestion = 0,
    this.skippedEmptyAnswer = 0,
  });

  final List<ParsedCardRow> cards;
  final int skipped;
  final int skippedEmptyQuestion;
  final int skippedEmptyAnswer;
  final String delimiter;
}

abstract final class CsvParser {
  static const questionHeaders = {
    'frage',
    'question',
    'q',
    'front',
    'vorderseite',
    'prompt',
    'kartenfrage',
    'lernfrage',
    'begriff',
    'term',
  };

  static const answerHeaders = {
    'antwort',
    'answer',
    'a',
    'losung',
    'loesung',
    'solution',
    'back',
    'ruckseite',
    'rueckseite',
    'erklarung',
    'erklaerung',
    'definition',
  };

  static const wrongAnswerHeaders = [
    {
      'falscheantwort1',
      'wronganswer1',
      'distractor1',
      'falsch1',
      'incorrect1',
    },
    {
      'falscheantwort2',
      'wronganswer2',
      'distractor2',
      'falsch2',
      'incorrect2',
    },
    {
      'falscheantwort3',
      'wronganswer3',
      'distractor3',
      'falsch3',
      'incorrect3',
    },
  ];

  static String decodeBytes(List<int> bytes) {
    var data = bytes;
    if (data.length >= 3 &&
        data[0] == 0xEF &&
        data[1] == 0xBB &&
        data[2] == 0xBF) {
      data = data.sublist(3);
    }
    try {
      return utf8.decode(data);
    } catch (_) {
      return latin1.decode(data);
    }
  }

  static CsvDocument parseDocument(String text) {
    var normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (normalized.startsWith('\uFEFF')) {
      normalized = normalized.substring(1);
    }
    final records = _parseRecords(normalized);
    if (records.isEmpty) {
      return const CsvDocument(headers: [], rows: [], delimiter: ',');
    }
    final delimiter = _detectDelimiter(records);
    final split = records
        .map((line) => _splitRecord(line, delimiter))
        .where((cols) => cols.any((c) => c.trim().isNotEmpty))
        .toList();
    if (split.isEmpty) {
      return CsvDocument(headers: const [], rows: const [], delimiter: delimiter);
    }
    final headers = split.first.map((h) => h.trim()).toList();
    final rows = split.skip(1).toList();
    return CsvDocument(headers: headers, rows: rows, delimiter: delimiter);
  }

  static CsvParseResult parseCards(String text) {
    final doc = parseDocument(text);
    if (doc.headers.isEmpty) {
      return CsvParseResult(
        cards: const [],
        skipped: 0,
        delimiter: doc.delimiter,
      );
    }

    final qIndex = _findHeader(doc.headers, questionHeaders);
    final aIndex = _findHeader(doc.headers, answerHeaders);
    final w1 = _findHeader(doc.headers, wrongAnswerHeaders[0]);
    final w2 = _findHeader(doc.headers, wrongAnswerHeaders[1]);
    final w3 = _findHeader(doc.headers, wrongAnswerHeaders[2]);

    late final int qi;
    late final int ai;
    late final List<List<String>> dataRows;
    if (qIndex != null && aIndex != null && qIndex != aIndex) {
      qi = qIndex;
      ai = aIndex;
      dataRows = doc.rows;
    } else if (doc.headers.length >= 2) {
      qi = 0;
      ai = 1;
      dataRows = [doc.headers, ...doc.rows];
    } else {
      return CsvParseResult(
        cards: const [],
        skipped: doc.rows.length,
        delimiter: doc.delimiter,
      );
    }

    final cards = <ParsedCardRow>[];
    var skipped = 0;
    var skippedEmptyQuestion = 0;
    var skippedEmptyAnswer = 0;
    for (final row in dataRows) {
      final q = qi < row.length ? row[qi].trim() : '';
      final a = ai < row.length ? row[ai].trim() : '';
      if (q.isEmpty && a.isEmpty) {
        skipped++;
        continue;
      }
      if (q.isEmpty) {
        skippedEmptyQuestion++;
        skipped++;
        continue;
      }
      if (a.isEmpty) {
        skippedEmptyAnswer++;
        skipped++;
        continue;
      }
      cards.add(
        ParsedCardRow(
          question: q,
          answer: a,
          wrongAnswer1: _cell(row, w1),
          wrongAnswer2: _cell(row, w2),
          wrongAnswer3: _cell(row, w3),
        ),
      );
    }

    return CsvParseResult(
      cards: cards,
      skipped: skipped,
      skippedEmptyQuestion: skippedEmptyQuestion,
      skippedEmptyAnswer: skippedEmptyAnswer,
      delimiter: doc.delimiter,
    );
  }

  static String topicNameFromFilename(String filename) {
    var name = filename.replaceAll('\\', '/').split('/').last;
    if (name.toLowerCase().endsWith('.csv')) {
      name = name.substring(0, name.length - 4);
    }
    return name.trim();
  }

  static String normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _cell(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].trim();
  }

  static int? _findHeader(List<String> headers, Set<String> aliases) {
    for (var i = 0; i < headers.length; i++) {
      final key = _headerKey(headers[i]);
      if (aliases.contains(key)) return i;
    }
    return null;
  }

  static String _headerKey(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[\s_\-]+'), '');
  }

  static List<String> _parseRecords(String text) {
    final records = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < text.length && text[i + 1] == '"') {
          buf.write('""');
          i++;
        } else {
          inQuotes = !inQuotes;
          buf.write(ch);
        }
      } else if (ch == '\n' && !inQuotes) {
        records.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) records.add(buf.toString());
    return records;
  }

  static String _detectDelimiter(List<String> records) {
    const candidates = [';', ',', '\t', '|'];
    final sample = records.take(8).toList();
    var best = ',';
    var bestScore = -1;
    for (final d in candidates) {
      var score = 0;
      int? cols;
      for (final line in sample) {
        final n = _splitRecord(line, d).length;
        if (n <= 1) continue;
        cols ??= n;
        if (n == cols) score += n;
      }
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best;
  }

  static List<String> _splitRecord(String record, String delimiter) {
    final cols = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < record.length; i++) {
      final ch = record[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < record.length && record[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == delimiter && !inQuotes) {
        cols.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    cols.add(buf.toString());
    return cols.map((c) => c.trim()).toList();
  }
}
