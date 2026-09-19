/// Normalisierung und Duplikaterkennung für Quizfragen.
///
/// Lokal, ohne KI: Groß/Klein, Leerzeichen, Satzzeichen, Umlaute und
/// gleichbedeutende Fragesätze („Was ist DHCP?“ / „Was bedeutet DHCP?“).
abstract final class QuestionNormalizer {
  static const _stop = {
    'ein',
    'eine',
    'einer',
    'eines',
    'einem',
    'einen',
    'der',
    'die',
    'das',
    'den',
    'dem',
    'des',
    'und',
    'oder',
    'von',
    'vom',
    'im',
    'in',
    'am',
    'an',
    'auf',
    'mit',
    'bei',
    'fur',
    'fuer',
    'zu',
    'zum',
    'zur',
    'ist',
    'sind',
    'hat',
    'haben',
    'wird',
    'werden',
    'wie',
    'was',
    'welche',
    'welcher',
    'welches',
    'welchen',
  };

  /// Längere Präfixe zuerst.
  static const _prefixes = [
    'wofuer steht die abkuerzung ',
    'wofuer steht ',
    'was versteht man unter ',
    'was bezeichnet man als ',
    'was ist der unterschied zwischen ',
    'was sind die aufgaben von ',
    'welche hauptaufgaben hat ',
    'welche aufgabe hat ',
    'welchen zweck hat ',
    'wozu dient ',
    'was bewirkt ',
    'was macht ',
    'was bedeutet ',
    'was bezeichnet ',
    'was beschreibt ',
    'wie funktioniert ',
    'wie arbeitet ',
    'erkläre ',
    'erklaere ',
    'erlaeutere ',
    'erläutere ',
    'definiere ',
    'beschreibe ',
    'nenne ',
    'erklare ',
    'aus wie vielen ',
    'wie viele ',
    'wieviel ',
    'was ist ein ',
    'was ist eine ',
    'was ist der ',
    'was ist die ',
    'was ist das ',
    'was ist ',
  ];

  static String fold(String value) {
    return value
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
  }

  static String normalize(String value) {
    var text = fold(value).replaceAll(RegExp(r'[^a-z0-9./+\s]'), ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Kern der Frage nach Entfernen typischer Frageformeln.
  static String fingerprint(String question) {
    var text = normalize(question);
    var changed = true;
    while (changed && text.isNotEmpty) {
      changed = false;
      for (final prefix in _prefixes) {
        final foldedPrefix = fold(prefix);
        if (text.startsWith(foldedPrefix)) {
          text = text.substring(foldedPrefix.length).trim();
          changed = true;
          break;
        }
      }
    }
    while (true) {
      final parts = text.split(' ');
      if (parts.isEmpty || !_stop.contains(parts.first)) break;
      text = parts.skip(1).join(' ').trim();
    }
    text = text.replaceAll(RegExp(r'[./+]+$'), '').trim();
    return text;
  }

  static Set<String> tokens(String text) {
    return normalize(text)
        .split(' ')
        .where((w) => w.length >= 2 || RegExp(r'\d').hasMatch(w))
        .map(_stem)
        .toSet();
  }

  static Set<String> significantTokens(String text) {
    return tokens(text).difference(_stop);
  }

  static String _stem(String word) {
    if (word.length <= 4) return word;
    for (final suffix in ['ern', 'en', 'em', 'er', 'es', 'e']) {
      if (word.endsWith(suffix) && word.length - suffix.length >= 3) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    return word;
  }

  static QuestionKind kindOf(String question) {
    final s = fold(question.trim());
    if (RegExp(r'^(ja|nein)\b').hasMatch(s)) return QuestionKind.yesNo;
    if (s.startsWith('wie viele') ||
        s.startsWith('wieviel') ||
        s.startsWith('aus wie vielen') ||
        s.startsWith('wie oft') ||
        s.startsWith('wie berechnet') ||
        s.contains('wie viele bit') ||
        s.contains('wie vielen bit')) {
      return QuestionKind.quantity;
    }
    if (s.startsWith('was macht') ||
        s.startsWith('wozu dient') ||
        s.startsWith('was bewirkt') ||
        s.contains('aufgabe hat') ||
        s.startsWith('wie funktioniert')) {
      return QuestionKind.action;
    }
    if (s.startsWith('was ist') ||
        s.startsWith('was bedeutet') ||
        s.startsWith('wofuer steht') ||
        s.startsWith('was bezeichnet') ||
        s.startsWith('erkl') ||
        s.startsWith('definier')) {
      return QuestionKind.definition;
    }
    return QuestionKind.other;
  }

  static String subjectOf(String question, String answer) {
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
      RegExp(r'^Was ist der Unterschied zwischen (.+)$', caseSensitive: false),
      RegExp(
        r'^Was ist (?:ein |eine |der |die |das )?(.+)$',
        caseSensitive: false,
      ),
      RegExp(r'^Welche[rsn]? Hauptaufgaben hat (.+)$', caseSensitive: false),
      RegExp(r'^Welche[rsn]? Aufgabe hat (.+)$', caseSensitive: false),
      RegExp(
        r'^(?:Aus )?wie viele[n]? .+\b(?:eine |ein |der |die |das )(.+)$',
        caseSensitive: false,
      ),
      RegExp(r'^Erkläre (.+)$', caseSensitive: false),
      RegExp(r'^Definiere (.+)$', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(q);
      if (match != null) {
        var subject = match.group(1)!.trim();
        subject = subject.replaceFirst(
          RegExp(
            r'^(ein|eine|der|die|das|den|dem|des)\s+',
            caseSensitive: false,
          ),
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
    final fp = fingerprint(question);
    if (fp.isNotEmpty) return fp.split(' ').take(4).join(' ');
    return q.split(' ').take(3).join(' ');
  }

  static bool mentionsSubject(String text, String subject) {
    final hay = normalize(text);
    final needle = normalize(subject);
    if (needle.isEmpty) return false;
    final parts = needle.split(' ').where((w) => w.length >= 3).toList();
    final head = parts.isEmpty ? needle : parts.first;
    if (head.length < 3) return hay.contains(needle);
    return hay.contains(head);
  }

  /// Konservativ: nur eindeutige oder sehr nahe Formulierungen derselben Frage.
  static bool areDuplicates(String a, String b) {
    final na = normalize(a);
    final nb = normalize(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;

    final fa = fingerprint(a);
    final fb = fingerprint(b);
    if (fa.isEmpty || fb.isEmpty) return false;
    if (fa == fb) return true;

    final sa = significantTokens(fa);
    final sb = significantTokens(fb);
    if (sa.isEmpty || sb.isEmpty) return false;
    if (sa.length <= 3 && sa == sb) return true;

    final inter = sa.intersection(sb).length;
    final union = sa.union(sb).length;
    if (union == 0) return false;
    final jaccard = inter / union;
    if (jaccard >= 0.82) return true;

    if (kindOf(a) == kindOf(b) &&
        sa.length >= 2 &&
        sb.length >= 2 &&
        sa.difference(sb).isEmpty &&
        sb.difference(sa).isEmpty) {
      return true;
    }
    return false;
  }
}

enum QuestionKind { quantity, definition, action, yesNo, other }
