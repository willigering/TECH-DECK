import '../data/csv/csv_parser.dart';
import '../data/models/flashcard.dart';
import '../data/models/quiz.dart';

/// Baut vier thematisch passende Optionen aus EINER Karte.
/// Fachfremde Volldefinitionen anderer Begriffe werden verworfen.
abstract final class ThematicDistractors {
  static List<QuizOption>? choicesFor(Flashcard card) {
    final question = card.question.trim();
    final correct = card.answer.trim();
    if (question.isEmpty || correct.isEmpty) return null;

    final subject = extractSubject(question, correct);
    final kind = _questionKind(question);
    final seen = <String>{CsvParser.normalizeKey(correct)};
    final wrongs = <String>[];

    void add(String raw) {
      final text = raw.trim();
      if (text.isEmpty) return;
      if (!seen.add(CsvParser.normalizeKey(text))) return;
      wrongs.add(text);
    }

    for (final candidate in card.wrongAnswers) {
      if (wrongs.length >= 3) break;
      if (_isThematicFit(candidate, question, correct, subject, kind)) {
        add(candidate);
      }
    }
    for (final generated in _generateFor(question, correct, subject, kind)) {
      if (wrongs.length >= 3) break;
      add(generated);
    }
    if (wrongs.length < 3) return null;

    return [
      QuizOption(text: correct, isCorrect: true),
      for (final wrong in wrongs.take(3))
        QuizOption(text: wrong, isCorrect: false),
    ];
  }

  static String extractSubject(String question, String answer) {
    var q = question.trim();
    if (q.endsWith('?')) q = q.substring(0, q.length - 1).trim();

    final patterns = <RegExp>[
      RegExp(
        r'^Was macht (.+?)(?: unter| in\b| bei\b| auf\b| mit\b| für\b| durch\b|$)',
        caseSensitive: false,
      ),
      RegExp(r'^Was bewirkt (.+)$', caseSensitive: false),
      RegExp(r'^Wozu dient (.+)$', caseSensitive: false),
      RegExp(r'^Wofür steht(?: die Abkürzung)? (.+)$', caseSensitive: false),
      RegExp(r'^Was bedeutet (.+)$', caseSensitive: false),
      RegExp(r'^Was bezeichnet (.+)$', caseSensitive: false),
      RegExp(
        r'^Was ist der Unterschied zwischen (.+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'^Was ist (?:ein |eine |der |die |das )?(.+)$',
        caseSensitive: false,
      ),
      RegExp(r'^Welche[rsn]? Hauptaufgaben hat (.+)$', caseSensitive: false),
      RegExp(r'^Welche[rsn]? Aufgabe hat (.+)$', caseSensitive: false),
      RegExp(
        r'^Wie viele .+?\b(?:eine |ein |der |die |das )?(.+)$',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(q);
      if (match != null) {
        var subject = match.group(1)!.trim();
        subject = subject.replaceFirst(
          RegExp(r'^(ein|eine|der|die|das|den|dem|des)\s+', caseSensitive: false),
          '',
        );
        subject = subject.split(',').first.trim();
        if (subject.isNotEmpty) return subject;
      }
    }

    final fromAnswer = RegExp(
      r'^([A-Za-zÄÖÜäöü0-9][A-Za-zÄÖÜäöü0-9./+-]{1,40})\b',
    ).firstMatch(answer.trim());
    if (fromAnswer != null) return fromAnswer.group(1)!;
    return q.split(' ').take(3).join(' ');
  }

  static _QuestionKind _questionKind(String question) {
    final s = question.toLowerCase();
    if (s.startsWith('was macht') ||
        s.startsWith('wozu dient') ||
        s.startsWith('was bewirkt') ||
        s.contains('aufgabe hat')) {
      return _QuestionKind.action;
    }
    if (s.startsWith('wie viele') ||
        s.startsWith('wieviel') ||
        s.startsWith('wie oft') ||
        s.startsWith('wie berechnet')) {
      return _QuestionKind.quantity;
    }
    if (s.startsWith('was ist') ||
        s.startsWith('was bedeutet') ||
        s.startsWith('wofür steht') ||
        s.startsWith('was bezeichnet')) {
      return _QuestionKind.definition;
    }
    return _QuestionKind.other;
  }

  static bool _isThematicFit(
    String candidate,
    String question,
    String correct,
    String subject,
    _QuestionKind kind,
  ) {
    final text = candidate.trim();
    if (text.isEmpty) return false;
    if (CsvParser.normalizeKey(text) == CsvParser.normalizeKey(correct)) {
      return false;
    }
    if (mentionsSubject(text, subject)) return true;

    if (_hasNumber(correct) && _hasNumber(text) && _similarLength(text, correct)) {
      return true;
    }
    if (_isYesNo(correct) && _isYesNo(text)) return true;

    if (_definesOtherTerm(text, subject)) return false;

    if (kind == _QuestionKind.definition) return false;

    if (kind == _QuestionKind.action &&
        _isCommandAction(correct) &&
        _isCommandAction(text) &&
        text.length < (correct.length * 2.4).round() + 24) {
      return true;
    }
    return false;
  }

  static bool mentionsSubject(String text, String subject) {
    final hay = CsvParser.normalizeKey(text);
    final needle = CsvParser.normalizeKey(subject);
    if (needle.isEmpty) return false;
    final parts = needle.split(' ').where((w) => w.length >= 3).toList();
    final head = parts.isEmpty ? needle : parts.first;
    return hay.contains(head);
  }

  static bool _definesOtherTerm(String text, String subject) {
    final def = _definitionStart.firstMatch(text.trim());
    if (def == null) {
      final bei = _beiStart.firstMatch(text.trim());
      if (bei == null) return false;
      return !mentionsSubject(bei.group(1)!, subject);
    }
    return !mentionsSubject(def.group(1)!, subject);
  }

  static bool _isCommandAction(String text) {
    return _commandAction.hasMatch(text.trim());
  }

  static Iterable<String> _generateFor(
    String question,
    String answer,
    String subject,
    _QuestionKind kind,
  ) {
    final out = <String>[];
    if (_isYesNo(answer)) {
      out.addAll(_yesNoVariants(answer));
    }
    out.addAll(_numericVariants(answer));
    if (!_isShortNumeric(answer)) {
      out.addAll(_verbMutations(answer));
      out.addAll(_nounMutations(answer));
      out.addAll(_templates(subject, kind));
    }
    return out;
  }

  static bool _isShortNumeric(String answer) {
    return _hasNumber(answer) && answer.trim().length <= 48;
  }

  static List<String> _numericVariants(String answer) {
    final matches = RegExp(r'\d+').allMatches(answer).toList();
    if (matches.isEmpty) return const [];
    final variants = <String>{};
    for (final match in matches) {
      final n = int.tryParse(match.group(0)!);
      if (n == null) continue;
      for (final v in _nearby(n)) {
        variants.add(answer.replaceRange(match.start, match.end, '$v'));
      }
    }
    return variants.toList();
  }

  static List<int> _nearby(int n) {
    final set = <int>{};
    if (n > 1) {
      set.add(n - 1);
      set.add(n + 1);
    }
    if (n > 2) set.add(n - 2);
    set.add(n + 2);
    if (n > 1) set.add(n * 2);
    if (n % 2 == 0 && n > 2) set.add(n ~/ 2);
    for (final v in const [4, 7, 8, 16, 24, 32, 64, 128, 256, 512, 1024]) {
      if (v != n) set.add(v);
    }
    set.remove(n);
    set.removeWhere((v) => v <= 0);
    return set.toList();
  }

  static List<String> _verbMutations(String answer) {
    final out = <String>[];
    for (final entry in _verbs.entries) {
      if (!answer.contains(entry.key)) continue;
      for (final replacement in entry.value) {
        out.add(answer.replaceFirst(entry.key, replacement));
      }
    }
    return out;
  }

  static List<String> _nounMutations(String answer) {
    final out = <String>[];
    for (final entry in _nouns.entries) {
      if (!answer.contains(entry.key)) continue;
      for (final replacement in entry.value) {
        out.add(answer.replaceFirst(entry.key, replacement));
      }
    }
    return out;
  }

  static List<String> _templates(String subject, _QuestionKind kind) {
    final s = subject.trim();
    if (s.isEmpty) return const [];
    if (kind == _QuestionKind.action) {
      return [
        '$s löscht Dateien und Einstellungen ohne Nachfrage.',
        '$s startet alle Systemdienste neu.',
        '$s ändert den Rechnernamen.',
        '$s blockiert jede Anmeldung am System.',
      ];
    }
    return [
      '$s speichert ausschließlich Passwörter und Zugangsdaten.',
      '$s ersetzt ein vollständiges Backup aller Dateien.',
      '$s ist nur eine mündliche Absprache ohne schriftliche Aufzeichnung.',
      '$s bezeichnet ausschließlich die Stromversorgung eines Rechners.',
    ];
  }

  static List<String> _yesNoVariants(String answer) {
    final compact = _compact(answer);
    if (compact == 'ja' || compact == 'yes' || compact == 'wahr' || compact == 'true') {
      return const ['Nein', 'Nur in Ausnahmefällen', 'Das ist nicht festgelegt'];
    }
    if (compact == 'nein' || compact == 'no' || compact == 'falsch' || compact == 'false') {
      return const ['Ja', 'Nur in Ausnahmefällen', 'Das ist nicht festgelegt'];
    }
    return const [];
  }

  static bool _hasNumber(String text) => RegExp(r'\d').hasMatch(text);

  static bool _similarLength(String a, String b) {
    final x = a.trim().length;
    final y = b.trim().length;
    if (x == 0 || y == 0) return false;
    final ratio = (x < y ? x / y : y / x);
    return ratio >= 0.35;
  }

  static bool _isYesNo(String answer) {
    const values = {
      'ja',
      'nein',
      'yes',
      'no',
      'wahr',
      'falsch',
      'true',
      'false',
    };
    return values.contains(_compact(answer));
  }

  static String _compact(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');
  }

  static final _definitionStart = RegExp(
    r'^(?:Ein |Eine |Der |Die |Das )?'
    r'([A-Za-zÄÖÜäöü0-9][A-Za-zÄÖÜäöü0-9./+-]{1,40})'
    r'\s+(ist|sind|bedeutet|bezeichnet|umfasst|beschreibt|regelt|enthält)\b',
    caseSensitive: false,
  );
  static final _beiStart = RegExp(
    r'^Bei ([A-Za-zÄÖÜäöü0-9./+-]+)\b',
    caseSensitive: false,
  );
  static final _commandAction = RegExp(
    r'^[A-Za-z][A-Za-z0-9._+-]{1,24}\s+(ändert|ändert|erlaubt|setzt|startet|beendet|löscht|kopiert|zeigt|prüft|öffnet)',
    caseSensitive: false,
  );
}

enum _QuestionKind { action, definition, quantity, other }

const _verbs = {
  'ändert': ['löscht', 'erstellt', 'kopiert'],
  'verwaltet': ['ignoriert', 'blockiert', 'löscht'],
  'hält': ['löscht', 'versteckt', 'verschlüsselt'],
  'ermöglicht': ['verhindert', 'blockiert', 'beendet'],
  'verhindert': ['erzwingt', 'erlaubt', 'startet'],
  'erlaubt': ['verbietet', 'löscht', 'beendet'],
  'organisiert': ['löscht', 'blockiert', 'verschlüsselt'],
  'vermittelt': ['blockiert', 'ignoriert', 'ersetzt'],
  'erweitert': ['verringert', 'blockiert', 'löscht'],
  'erhöht': ['verringert', 'beendet', 'löscht'],
  'trennt': ['verbindet dauerhaft', 'löscht', 'kopiert'],
  'speichert': ['löscht', 'ignoriert', 'sendet unverschlüsselt'],
  'prüft': ['ignoriert', 'löscht', 'startet'],
  'startet': ['beendet', 'löscht', 'blockiert'],
  'besitzt': ['besitzt keine', 'löscht', 'versteckt'],
  'besteht': ['besteht nicht', 'verhindert', 'löscht'],
};

const _nouns = {
  'Zugriffsrechte': ['Dateinamen', 'Besitzer', 'Dateiinhalte'],
  'Besitzer': ['Dateinamen', 'Zugriffsrechte', 'Dateiendung'],
  'Dateien und Verzeichnissen': [
    'Benutzerkonten',
    'Netzwerkverbindungen',
    'Systemdiensten',
  ],
  'Dateien und Verzeichnisse': [
    'Benutzerkonten',
    'Netzwerkverbindungen',
    'Systemdienste',
  ],
  'Arbeitsspeicher': ['Druckerwarteschlange', 'Bildschirmschoner', 'Lautstärke'],
  'Netzanteil': ['Dateinamen', 'Benutzerpasswort', 'Druckername'],
  'Hostanteil': ['Dateiendung', 'Bildschirmauflösung', 'Lautstärke'],
};
