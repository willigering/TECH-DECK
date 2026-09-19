import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech_deck/data/ai/ai_settings.dart';
import 'package:tech_deck/data/ai/distractor_api.dart';
import 'package:tech_deck/data/csv/csv_parser.dart';
import 'package:tech_deck/data/models/flashcard.dart';
import 'package:tech_deck/logic/distractor_validator.dart';
import 'package:tech_deck/logic/import_analyzer.dart';

void main() {
  test('CSV nur Frage und Antwort', () {
    const csv = 'Frage;Antwort\nWie viele Bits hat IPv4?;32 Bit\n';
    final parsed = CsvParser.parseCards(csv);
    expect(parsed.cards, hasLength(1));
    expect(parsed.cards.single.wrongAnswers, ['', '', '']);
    final analysis = ImportAnalyzer.fromParse(
      filename: 'netz.csv',
      parsed: parsed,
    );
    expect(analysis.missingCount, 1);
    expect(analysis.quizReadyCount, 0);
  });

  test('CSV mit vollständigen Distraktoren', () {
    const csv =
        'Frage;Antwort;FalscheAntwort1;FalscheAntwort2;FalscheAntwort3\n'
        'Wie viele Bits hat IPv4?;32 Bit;16 Bit;64 Bit;128 Bit\n';
    final parsed = CsvParser.parseCards(csv);
    final analysis = ImportAnalyzer.fromParse(
      filename: 'netz.csv',
      parsed: parsed,
    );
    expect(analysis.quizReadyCount, 1);
    expect(
      DistractorValidator.normalizeThree(
        parsed.cards.single.wrongAnswers,
        '32 Bit',
      ),
      ['16 Bit', '64 Bit', '128 Bit'],
    );
  });

  test('leere Frage wird übersprungen', () {
    const csv = 'Frage;Antwort\n;32 Bit\nWas ist RAM?;Arbeitsspeicher\n';
    final parsed = CsvParser.parseCards(csv);
    expect(parsed.skippedEmptyQuestion, 1);
    expect(parsed.cards, hasLength(1));
  });

  test('leere richtige Antwort wird übersprungen', () {
    const csv = 'Frage;Antwort\nWas ist RAM?;\nWas ist ROM?;Festwertspeicher\n';
    final parsed = CsvParser.parseCards(csv);
    expect(parsed.skippedEmptyAnswer, 1);
    expect(parsed.cards, hasLength(1));
  });

  test('weniger als drei falsche Antworten', () {
    expect(
      DistractorValidator.normalizeThree(['16 Bit', '64 Bit'], '32 Bit'),
      isNull,
    );
  });

  test('doppelte Antworten', () {
    expect(
      DistractorValidator.normalizeThree([
        '16 Bit',
        '16 Bit',
        '64 Bit',
      ], '32 Bit'),
      isNull,
    );
  });

  test('richtige Antwort als Distraktor', () {
    expect(
      DistractorValidator.normalizeThree([
        '32 Bit',
        '16 Bit',
        '64 Bit',
      ], '32 Bit'),
      isNull,
    );
  });

  test('KI liefert nur zwei Distraktoren', () {
    expect(
      DistractorValidator.normalizeThree(['16 Bit', '64 Bit'], '32 Bit'),
      isNull,
    );
  });

  test('KI liefert vier Distraktoren', () {
    expect(
      DistractorValidator.normalizeThree([
        '16 Bit',
        '64 Bit',
        '128 Bit',
        '8 Bit',
      ], '32 Bit'),
      isNull,
    );
  });

  test('KI liefert Duplikate', () {
    expect(
      DistractorValidator.issueFor(['16 Bit', '16 bit', '64 Bit'], '32 Bit'),
      isNotNull,
    );
  });

  test('Backend-Fehler wird als Exception gemeldet', () async {
    SharedPreferences.setMockInitialValues({
      'ai_backend_url': 'http://127.0.0.1:8787',
    });
    final api = DistractorApi(
      settings: AiSettings(),
      client: MockClient(
        (request) async => http.Response('{"detail":"down"}', 502),
      ),
    );
    expect(
      () => api.generate(question: 'Q', correctAnswer: 'A'),
      throwsA(isA<DistractorApiException>()),
    );
  });

  test('gültige Karte mit drei Falschantworten', () {
    final check = DistractorValidator.evaluate(
      question: 'Aus wie vielen Bits besteht eine IPv4-Adresse?',
      correctAnswer: '32 Bit',
      wrongAnswers: ['16 Bit', '64 Bit', '128 Bit'],
    );
    expect(check.ok, isTrue);
    expect(
      DistractorValidator.isQuizReady(
        Flashcard(
          id: '1',
          topicId: 't',
          question: 'Aus wie vielen Bits besteht eine IPv4-Adresse?',
          answer: '32 Bit',
          wrongAnswer1: '16 Bit',
          wrongAnswer2: '64 Bit',
          wrongAnswer3: '128 Bit',
        ),
      ),
      isTrue,
    );
  });

  test('Karte ohne Falschantworten', () {
    expect(
      DistractorValidator.evaluate(
        question: 'Was ist DHCP?',
        correctAnswer: 'Vergibt IP-Adressen',
        wrongAnswers: ['', '', ''],
      ).ok,
      isFalse,
    );
  });

  test('Falschantwort gleich der richtigen Antwort', () {
    expect(
      DistractorValidator.normalizeThree([
        '32 Bit',
        '16 Bit',
        '64 Bit',
      ], '32 Bit'),
      isNull,
    );
  });

  test('drei fachlich irrelevante Falschantworten', () {
    final check = DistractorValidator.evaluate(
      question: 'Aus wie vielen Bits besteht eine IPv4-Adresse?',
      correctAnswer: '32 Bit',
      wrongAnswers: [
        'Ein DNS-Server übersetzt Domainnamen',
        'Ein Switch arbeitet auf Layer 2',
        'DHCP vergibt IP-Adressen',
      ],
    );
    expect(check.ok, isFalse);
    expect(check.semanticIssues, isNotEmpty);
  });

  test('zwei identische Fragen im Import', () {
    const csv =
        'Frage;Antwort;FalscheAntwort1;FalscheAntwort2;FalscheAntwort3\n'
        'Was ist DHCP?;Vergibt IP-Adressen im Netz.;DHCP entzieht IP-Adressen.;DHCP übersetzt nur Namen.;DHCP arbeitet nur mit MAC-Adressen.\n'
        'Was ist DHCP?;Vergibt IP-Adressen im Netz.;DHCP entzieht IP-Adressen.;DHCP übersetzt nur Namen.;DHCP arbeitet nur mit MAC-Adressen.\n';
    final analysis = ImportAnalyzer.fromParse(
      filename: 'netz.csv',
      parsed: CsvParser.parseCards(csv),
    );
    expect(analysis.duplicateCount, 1);
    expect(analysis.quizReadyCount, 1);
  });

  test('zwei Fragen mit unterschiedlicher Schreibweise', () {
    const csv =
        'Frage;Antwort;FalscheAntwort1;FalscheAntwort2;FalscheAntwort3\n'
        'Was ist DHCP?;Vergibt IP-Adressen im Netz.;DHCP entzieht IP-Adressen.;DHCP übersetzt nur Namen.;DHCP arbeitet nur mit MAC-Adressen.\n'
        'Was bedeutet DHCP?;Vergibt IP-Adressen im Netz.;DHCP entzieht IP-Adressen.;DHCP übersetzt nur Namen.;DHCP arbeitet nur mit MAC-Adressen.\n';
    final analysis = ImportAnalyzer.fromParse(
      filename: 'netz.csv',
      parsed: CsvParser.parseCards(csv),
    );
    expect(analysis.duplicateCount, 1);
  });

  test('ungültige KI-JSON wird nicht akzeptiert', () async {
    SharedPreferences.setMockInitialValues({
      'ai_backend_url': 'http://127.0.0.1:8787',
    });
    final api = DistractorApi(
      settings: AiSettings(),
      client: MockClient(
        (request) async => http.Response('{"wrongAnswers":["nur eine"]}', 200),
      ),
    );
    expect(
      () => api.generate(question: 'Q', correctAnswer: 'A'),
      throwsA(isA<DistractorApiException>()),
    );
  });
}
