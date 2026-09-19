import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/data/models/flashcard.dart';
import 'package:tech_deck/logic/quiz_generator.dart';
import 'package:tech_deck/logic/study_order.dart';
import 'package:tech_deck/ui/widgets/flip_card.dart';
import 'package:flutter/material.dart';

void main() {
  Flashcard card(
    String id,
    String q,
    String a, {
    String w1 = '',
    String w2 = '',
    String w3 = '',
  }) => Flashcard(
    id: id,
    topicId: 'topic',
    question: q,
    answer: a,
    wrongAnswer1: w1,
    wrongAnswer2: w2,
    wrongAnswer3: w3,
  );

  Flashcard complete(String id, String q, String a) {
    final unit = a.contains('Bit')
        ? [
            '8 Bit',
            '16 Bit',
            '24 Bit',
            '64 Bit',
            '256 Bit',
          ].where((e) => e != a).take(3).toList()
        : a.contains('Oktette')
        ? ['2 Oktette', '6 Oktette', '8 Oktette']
        : a.trim() == '7'
        ? ['4', '8', '16']
        : ['4', '8', '16'];
    return card(id, q, a, w1: unit[0], w2: unit[1], w3: unit[2]);
  }

  test('erzeugt nur Fragen aus den übergebenen Karten', () {
    final cards = [
      complete('1', 'Wie viele Bits hat IPv4?', '32 Bit'),
      complete('2', 'Wie viele Oktette hat IPv4?', '4 Oktette'),
      complete('3', 'Wie viele Bits hat IPv6?', '128 Bit'),
      complete('4', 'Wie viele Schichten hat das OSI-Modell?', '7'),
    ];
    final questions = QuizGenerator(random: Random(1)).generate(cards, 10);
    expect(questions.length, 4);
    expect(questions.map((q) => q.cardId).toSet(), {'1', '2', '3', '4'});
    for (final q in questions) {
      expect(q.choices.where((c) => c.isCorrect), hasLength(1));
      expect(q.choices.singleWhere((c) => c.isCorrect).text, q.correctAnswer);
    }
  });

  test('keine doppelten Karten in einer Runde', () {
    final cards = [
      complete('1', 'Frage A?', 'A'),
      complete('1', 'Frage A?', 'A'),
      complete('2', 'Frage B?', 'B'),
    ];
    final questions = QuizGenerator(random: Random(1)).generate(cards, 10);
    expect(questions.map((q) => q.cardId).toSet().length, questions.length);
  });

  test('gleiche Frage nur einmal pro Runde', () {
    final cards = [
      complete('1', 'Wie viele Bits hat IPv4?', '32 Bit'),
      complete('2', 'Wie viele Bits hat IPv4?', '32 Bit'),
    ];
    final questions = QuizGenerator(random: Random(2)).generate(cards, 10);
    expect(questions, hasLength(1));
  });

  test('nutzt nur gespeicherte Distraktoren derselben Karte', () {
    final cards = [
      card(
        '1',
        'Aus wie vielen Bits besteht eine IPv4-Adresse?',
        '32 Bit',
        w1: '16 Bit',
        w2: '64 Bit',
        w3: '128 Bit',
      ),
      card(
        '2',
        'Was macht ein SELECT in SQL?',
        'Datensätze lesen',
        w1: 'SELECT fügt Datensätze ein',
        w2: 'SELECT ändert Datensätze',
        w3: 'SELECT löscht Datensätze',
      ),
    ];
    final questions = QuizGenerator(random: Random(7)).generate(cards, 8);
    final ipv4 = questions.firstWhere((q) => q.cardId == '1');
    expect(ipv4.options.toSet(), {'32 Bit', '16 Bit', '64 Bit', '128 Bit'});
    expect(ipv4.options, isNot(contains('Datensätze lesen')));
  });

  test('nimmt niemals Antworten anderer Karten', () {
    final cards = [
      card(
        '1',
        'Was ist CSMA/CD?',
        'Zugriffsverfahren bei Kollisionen.',
        w1: 'CSMA/CD ignoriert Kollisionen vollständig.',
        w2: 'CSMA/CD arbeitet nur auf Layer 3.',
        w3: 'CSMA/CD vergibt IP-Adressen.',
      ),
      card(
        '2',
        'Welche Topologie?',
        'Bustopologie',
        w1: 'Sterntopologie',
        w2: 'Ringtopologie',
        w3: 'Mesh-Topologie',
      ),
    ];
    final first = QuizGenerator(random: Random(3)).questionFor(cards.first)!;
    expect(first.options.toSet(), {
      'Zugriffsverfahren bei Kollisionen.',
      'CSMA/CD ignoriert Kollisionen vollständig.',
      'CSMA/CD arbeitet nur auf Layer 3.',
      'CSMA/CD vergibt IP-Adressen.',
    });
    expect(first.options, isNot(contains('Bustopologie')));
  });

  test('unvollständige Karten sind nicht quizfähig', () {
    final incomplete = card('1', 'Frage?', 'Richtig', w1: 'A', w2: 'B', w3: '');
    expect(QuizGenerator.isQuizReady(incomplete), isFalse);
    expect(QuizGenerator().questionFor(incomplete), isNull);
  });

  test('richtige Antwort als Distraktor macht die Karte ungültig', () {
    final bad = card(
      '1',
      'Bits?',
      '32 Bit',
      w1: '32 Bit',
      w2: '16 Bit',
      w3: '64 Bit',
    );
    expect(QuizGenerator.isQuizReady(bad), isFalse);
  });

  test('mischt nur die Reihenfolge, isCorrect bleibt', () {
    final c = card(
      '1',
      'Bits?',
      '32 Bit',
      w1: '16 Bit',
      w2: '64 Bit',
      w3: '128 Bit',
    );
    final a = QuizGenerator(random: Random(1)).questionFor(c)!;
    final b = QuizGenerator(random: Random(2)).questionFor(c)!;
    expect(a.options.toSet(), b.options.toSet());
    expect(a.choices.where((o) => o.isCorrect).single.text, '32 Bit');
    expect(a.options, isNot(equals(b.options)));
  });

  test('nahe Formulierungen derselben Frage nur einmal', () {
    final cards = [
      complete('1', 'Was ist DHCP?', '32 Bit'),
      complete('2', 'Was bedeutet DHCP?', '32 Bit'),
      complete('3', 'Erkläre DHCP.', '32 Bit'),
    ];
    final questions = QuizGenerator(random: Random(4)).generate(cards, 10);
    expect(questions, hasLength(1));
  });

  test('Quiz hat genau vier Antworten und eine richtige', () {
    final c = card(
      '1',
      'Bits?',
      '32 Bit',
      w1: '16 Bit',
      w2: '64 Bit',
      w3: '128 Bit',
    );
    final q = QuizGenerator(random: Random(5)).questionFor(c)!;
    expect(q.choices, hasLength(4));
    expect(q.choices.where((o) => o.isCorrect), hasLength(1));
  });

  test('mischt Lernkarten innerhalb des Decks', () {
    final ids = List<String>.generate(20, (i) => '$i');
    expect(shuffledCopy(ids, Random(1)), isNot(ids));
  });

  testWidgets('Lernmodus zeigt nur Frage und richtige Antwort', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlipStudyCard(
          question: 'Was ist Dokumentation?',
          answer: 'Schriftliche Nachweise zu Systemen.',
          flipped: true,
          onFlip: () {},
        ),
      ),
    );
    expect(find.text('Schriftliche Nachweise zu Systemen.'), findsOneWidget);
    expect(find.text('Redundanz bedeutet Ausfallschutz.'), findsNothing);
  });
}
