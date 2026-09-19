import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/core/app_info.dart';
import 'package:tech_deck/data/csv/csv_parser.dart';

void main() {
  test('App-Metadaten sind gesetzt', () {
    expect(AppInfo.name, 'TECH//DECK');
    expect(AppInfo.developer, 'Willi Gering');
    expect(AppInfo.version, '1.6.0');
    expect(AppInfo.buildNumber, 10);
    expect(AppInfo.tagline, 'LERNE. VERSTEHE. VERBINDE.');
  });

  test('Themenname bleibt in Importreihenfolge am Dateinamen', () {
    final names = [
      '01_Netzwerke.csv',
      '02_IPv4_IPv6.csv',
      '03_Betriebssysteme.csv',
    ].map(CsvParser.topicNameFromFilename).toList();
    expect(names, ['01_Netzwerke', '02_IPv4_IPv6', '03_Betriebssysteme']);
  });
}
