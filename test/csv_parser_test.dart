import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/data/csv/csv_parser.dart';

void main() {
  group('CsvParser', () {
    test('liest Frage/Antwort und erhält Umlaute', () {
      const csv =
          'Frage,Antwort\n'
          'Was ist ein Prozess?,Ein ausgeführtes Programm.\n'
          'Was ist eine Prüfung?,Die Abschlussprüfung.\n';
      final result = CsvParser.parseCards(csv);
      expect(result.cards, hasLength(2));
      expect(result.cards.first.question, 'Was ist ein Prozess?');
      expect(result.cards.first.answer, 'Ein ausgeführtes Programm.');
    });

    test('unterstützt Kommas und Anführungszeichen in Feldern', () {
      const csv =
          'Frage,Antwort\n'
          '"Was sind Hub, Switch und Router?","Geräte, die Netze verbinden."\n'
          '"Er sagte ""Hallo""","Eine Begrüßung"\n';
      final result = CsvParser.parseCards(csv);
      expect(result.cards, hasLength(2));
      expect(result.cards[0].question, 'Was sind Hub, Switch und Router?');
      expect(result.cards[0].answer, 'Geräte, die Netze verbinden.');
      expect(result.cards[1].question, 'Er sagte "Hallo"');
    });

    test('erkennt Semikolon als Delimiter', () {
      const csv =
          'Frage;Antwort\n'
          'Wie viele Bits hat IPv4?;32 Bit\n';
      final result = CsvParser.parseCards(csv);
      expect(result.cards, hasLength(1));
      expect(result.cards.first.answer, '32 Bit');
      expect(result.delimiter, ';');
    });

    test('mappt Question/Answer und überspringt leere Zeilen', () {
      const csv =
          'Question,Answer\n'
          '\n'
          'What is RAM?,Volatile memory\n'
          ',\n'
          'What is ROM?,Non-volatile memory\n';
      final result = CsvParser.parseCards(csv);
      expect(result.cards, hasLength(2));
      expect(result.cards[0].question, 'What is RAM?');
      expect(result.cards[1].question, 'What is ROM?');
    });

    test('nimmt Dateiname ohne .csv als Themenname', () {
      expect(
        CsvParser.topicNameFromFilename('01_Netzwerke.csv'),
        '01_Netzwerke',
      );
      expect(
        CsvParser.topicNameFromFilename(r'C:\Decks\02_IPv4_IPv6.CSV'),
        '02_IPv4_IPv6',
      );
    });

    test('dekodiert UTF-8 mit BOM', () {
      final bytes = <int>[
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('Frage,Antwort\nä,ö\n'),
      ];
      final text = CsvParser.decodeBytes(bytes);
      final result = CsvParser.parseCards(text);
      expect(result.cards, hasLength(1));
      expect(result.cards.first.question, 'ä');
      expect(result.cards.first.answer, 'ö');
    });

    test('behandelt CSV ohne Kopfzeile als Karten', () {
      const csv =
          'Wofür steht die Abkürzung CSMA/CD?,Carrier Sense Multiple Access / Collision Detection.\n'
          'Für welche physikalische Netzwerktopologie ist das CSMA/CD-Verfahren primär konzipiert?,Bustopologie.\n';
      final result = CsvParser.parseCards(csv);
      expect(result.cards, hasLength(2));
      expect(result.cards.first.question, 'Wofür steht die Abkürzung CSMA/CD?');
      expect(
        result.cards.first.answer,
        'Carrier Sense Multiple Access / Collision Detection.',
      );
    });

    test('ignoriert Thema-Spalte und nutzt Frage/Antwort', () {
      const csv =
          'Thema,Frage,Antwort\n'
          'Netzwerke,Was ist eine IP-Adresse?,Eine logische Adresse.\n';
      final result = CsvParser.parseCards(csv);
      expect(result.cards, hasLength(1));
      expect(result.cards.first.question, 'Was ist eine IP-Adresse?');
    });

    test('zählt leere Fragen und leere Antworten getrennt', () {
      const csv =
          'Frage;Antwort\n'
          ';32 Bit\n'
          'Was ist RAM?;\n'
          'Was ist ROM?;Festwertspeicher\n';
      final result = CsvParser.parseCards(csv);
      expect(result.skippedEmptyQuestion, 1);
      expect(result.skippedEmptyAnswer, 1);
      expect(result.cards, hasLength(1));
    });

    test('liest karten-eigene Falschantworten', () {
      const csv =
          'Frage;Antwort;FalscheAntwort1;FalscheAntwort2;FalscheAntwort3\n'
          'Aus wie vielen Bits besteht eine IPv4-Adresse?;32 Bit;16 Bit;64 Bit;128 Bit\n';
      final result = CsvParser.parseCards(csv);
      expect(result.cards, hasLength(1));
      final card = result.cards.single;
      expect(card.question, 'Aus wie vielen Bits besteht eine IPv4-Adresse?');
      expect(card.answer, '32 Bit');
      expect(card.wrongAnswers, ['16 Bit', '64 Bit', '128 Bit']);
    });

    test('parst alle mitgelieferten IT-Decks mit Distraktoren (16 x 50)', () {
      final dir = Directory('assets/decks');
      final files =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.csv'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(files, hasLength(16));
      var total = 0;
      for (final file in files) {
        final result = CsvParser.parseCards(file.readAsStringSync());
        expect(
          result.cards,
          hasLength(50),
          reason: '${file.uri.pathSegments.last} muss 50 Karten haben',
        );
        for (final card in result.cards) {
          expect(card.answer, isNotEmpty);
          expect(
            card.wrongAnswers.every((w) => w.trim().isNotEmpty),
            isTrue,
            reason: '${file.uri.pathSegments.last}: ${card.question}',
          );
        }
        total += result.cards.length;
      }
      expect(total, 800);
    });
  });
}
