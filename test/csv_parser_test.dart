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

    test('parst alle mitgelieferten IT-Decks', () {
      final dir = Directory('assets/decks');
      final files =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.csv'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      const expectedCards = {
        '01_IT_Grundlagen.csv': 54,
        '02_Hardware_und_Architektur.csv': 72,
        '03_Betriebssysteme.csv': 58,
        '04_Netzwerke_und_OSI.csv': 49,
        '05_IPv4_IPv6_Subnetting.csv': 51,
        '06_Netzwerkdienste_und_Protokolle.csv': 48,
        '07_IT_Sicherheit.csv': 71,
        '08_Datenbanken_und_SQL.csv': 52,
        '09_Programmierung_und_Skripting.csv': 50,
        '10_Virtualisierung_und_Cloud.csv': 49,
        '11_Webtechnologien.csv': 52,
        '12_DevOps_und_CICD.csv': 42,
        '13_IT_Service_Management.csv': 46,
        '14_Monitoring_Logging_Backup.csv': 48,
        '15_Datenschutz_Recht_Wirtschaft.csv': 70,
        '16_Pruefung_und_Fehleranalyse.csv': 45,
        '18_Windows_Terminal.csv': 50,
        '19_Linux_Terminal.csv': 50,
        '20_IT_Abkuerzungen_und_Akronyme.csv': 100,
        '22_Datenschutz_Privacy.csv': 51,
        '23_Schadsoftware.csv': 50,
        '24_Schutzbedarf.csv': 50,
        '25_Unternehmensformen.csv': 128,
      };
      expect(
        files.map((f) => f.uri.pathSegments.last).toList(),
        expectedCards.keys.toList(),
      );
      var total = 0;
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final result = CsvParser.parseCards(file.readAsStringSync());
        final expected = expectedCards[name]!;
        expect(
          result.cards,
          hasLength(expected),
          reason: '$name muss $expected Karten haben',
        );
        for (final card in result.cards) {
          expect(card.question, isNotEmpty);
          expect(card.answer, isNotEmpty);
        }
        total += result.cards.length;
      }
      expect(total, 1336);
    });
  });
}
