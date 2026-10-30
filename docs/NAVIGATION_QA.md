# Kartenauswahl: Umsetzung und Prüfbericht

Stand: 30.10.2026. Ausgangspunkt: `1fd72c449d67b60ef601b13902b4f37ca8b8860f` (`main`, veröffentlichte Version 1.7.12+23). Der Branch bereitet **1.7.13+24** vor; es wurde keine APK erstellt, kein Release angelegt/veröffentlicht und nichts gemergt.

## Bedienung

- Aufklappbare Fachkategorien mit Anzahl der Kartensätze und Summe ihrer Karten. Leere Kategorien werden nicht angezeigt.
- Decknamen werden vollständig umgebrochen; die Kartenanzahl steht darunter.
- Suche nach Kategorien, konfigurierten Schlagwörtern, Deck- und Dateinamen sowie Fragen/Antworten. Mehrere Suchwörter werden kombiniert, Umlaute/ae/oe/ue und Groß-/Kleinschreibung vereinheitlicht. Kartentexte werden beim ersten Suchen gelesen und für weitere Suchen zwischengespeichert. Nach einem erneuten Inhaltsladen wird der Index verworfen. Treffergruppen öffnen automatisch, lassen sich aber wieder schließen. Ohne Suchtext gilt der vorherige Aufklappzustand. Gruppenzahlen während einer Suche zählen die Treffer.
- Lesezeichen sind neue Favoriten, unabhängig von der bisherigen Wichtig-Markierung. Schnellfilter zeigen Favoriten, die fünf zuletzt geöffneten Decks und wichtige Decks direkt. Der neue Verlauf beginnt mit der ersten Nutzung dieser Version. Filter und Suchtext lassen sich kombinieren.
- Langdruck behält Farben und Wichtig-Schalter und ergänzt eine Kategorieauswahl. „Automatisch zuordnen“ stellt die regelbasierte Zuordnung wieder her.
- Regeln stehen in `assets/navigation/categories.json`; neue/importierte Decks werden automatisch einsortiert. Unbekannte Namen bleiben unter „Weitere Themen“ erreichbar. Neue Kategorien/Schlagwörter erfordern keine Änderungen am UI-Code.
- Vorhandene Designs und Akzentfarben bleiben erhalten. Auf-/Zuklappen verwendet 180 ms; bei deaktivierten Animationen entfällt die Größenanimation vollständig. Die Seite und das Markierungsmenü sind scrollbar.

## Datenbestand

SQLite-Schema bleibt Version 7. Deck- und Karten-IDs, Namen, Sortierreihenfolge, Importpfade und gebündelte Inhaltsrevision `learn-only-3` werden nicht geändert. Die bestehenden Datenbank-/Import-/Markierungs-Schreiboperationen sind unverändert; im Repository kommt ausschließlich eine lesende Suchindex-Methode hinzu. Es gibt keinen migrationsbedingten Neuimport und keine Rücksetzung von Nutzerdaten.

Die neue Navigation schreibt ausschließlich einen zusätzlichen SharedPreferences-Eintrag `deck_navigation_v1` mit Favoriten-IDs, bis zu fünf Verlaufs-IDs und Kategoriezuordnungen. Bestehende Einstellungen und `update_*`-Einträge bleiben unberührt. Gelöschte Decks werden nicht mehr in Schnellfiltern angezeigt.

Ein Test mit einer echten SQLite-Datei schließt und öffnet die Datenbank erneut: vorhandene und geänderte Farb-/Wichtig-Markierungen, Deck-/Karten-IDs, Kartenanzahl, Sortierung, bestehende Metadaten, Theme, Favoriten, Verlauf und Kategoriezuordnung werden geprüft. Ein zusätzlicher lokaler Lauf hat alle 26 gebündelten Decks importiert und die Kategorienansicht visuell geprüft.

## Update- und Signaturprüfung

Vor der Implementierung geprüft: `lib/update/*`, nativer Android-Updater, Gradle-Signierung, Release-Workflow-Vorlage, Metadatenerzeugung und veröffentlichte Release-Metadaten.

- Quelle bleibt `https://api.github.com/repos/willigering/TECH-DECK/releases/latest` mit den bestehenden HTTPS-/Host-, ETag-, Versions-, ABI-, Größen- und SHA-256-Prüfungen.
- Paketkennung bleibt `com.willigering.tech_deck`, `minSdk` bleibt 24.
- Der vorhandene Vertrauensanker ist das öffentliche Android-Signaturzertifikat der installierten App. Es wird zur Laufzeit über den PackageManager gelesen und mit dem Zertifikat der heruntergeladenen APK verglichen. Im Quellcode ist kein separater eingebetteter Public-Key für signierte Update-Manifeste vorhanden.
- Die öffentlich veröffentlichten Metadaten von `v1.7.12` nennen Version 1.7.12, Code 23 und den bekannten Zertifikat-Fingerprint `0cea186b…07ee754d`. Das passt zur vorhandenen Signierkonfiguration. Die veröffentlichten Assets wurden nicht geändert.
- Lokale Schlüsselquelle ist die ignorierte `android/key.properties` oder `TECHDECK_KEYSTORE_PATH` plus die vorhandenen Passwort-/Alias-Umgebungsvariablen. Die Workflow-Vorlage verwendet die dokumentierten GitHub-Secrets und prüft den resultierenden Zertifikat-Fingerprint gegen die Repository-Variable. Es gibt keinen Debug-Schlüssel-Fallback für Release-Builds.
- Hier sind weder `android/key.properties` noch ein Release-Keystore-Umgebungspfad vorhanden. Die Verfügbarkeit der GitHub-Secrets wurde nicht festgestellt. Es wurden keine privaten Schlüssel erzeugt, ersetzt, gelesen, veröffentlicht oder eingebettet; keine vermeintlich kompatible Release-APK wurde gebaut.
- 42 geschützte Dateien sind bytegenau identisch zum Ausgangspunkt: sämtliche Dateien unter `android/`, `lib/update/` und `lib/data/db/`, ferner `lib/data/models/topic.dart`, `lib/app.dart`, `lib/ui/screens/shell.dart`, beide Update-Widgets, `tool/update_metadata.py` und `tool/github-workflows/release-apk.yml`.
- Nur die geplante App-Version steigt konsistent auf 1.7.13+24. Endpunkte, Metadatenschema und Prüfmechanismen bleiben gleich. Der `pubspec.lock` ergänzt lediglich fünf Pakete für die SQLite-Tests; vorhandene Paketversionen bleiben unverändert.

Damit ist die Erhaltung der bestehenden Implementierung auf Quellcode- und automatisierter Testebene belegt. Die Signatur und Installierbarkeit einer zukünftigen Release-APK sind damit noch nicht praktisch nachgewiesen.

## Automatisierte Ergebnisse

Umgebung: Flutter 3.47.9, Dart 3.13.7, Linux. SQLite-Integration über die reine Entwicklungsabhängigkeit `sqflite_common_ffi`.

- `flutter analyze --no-pub`: keine Befunde.
- `flutter test --no-pub --reporter expanded`: **100 Tests erfolgreich**.
- Davon 20 neue Tests: Kategorien, automatische/manuelle Zuordnung, Suche in Titeln/Kategorien/Dateinamen/Karteninhalten, Literalbehandlung und Umlaute; Favoriten/Verlauf und gespeicherte Zuordnungen; echte SQLite-Wiederherstellung; Accordion, Langdruck/Farbe/Wichtig, Lernstart/Rückkehr, Suchlöschung/Nulltreffer; alle drei Designs bei 320×568 und 568×320 sowie 200 % Schrift und deaktivierten Animationen.
- Bestehende Update-Tests bleiben unverändert und erfolgreich: Versionsvergleich, Release-Auswahl, falsche Paketkennung, inkompatible Signatur, manipulierte Prüfsummen, Downloadabbruch, WLAN-Regel, fehlende Installationsfreigabe und Update-Oberfläche.
- `git diff --check`: sauber.

## Noch vor einem freigegebenen Release prüfen

1. Originalen Release-Schlüssel in der vorgesehenen sicheren Build-Umgebung verwenden; bei Fehlen abbrechen. Mit `apksigner verify --print-certs` denselben Fingerprint wie bei 1.7.12 nachweisen und Metadaten mit dem unveränderten Generator erzeugen.
2. Auf Android über eine bestehende, mit dem Originalschlüssel signierte 1.7.12-Installation aktualisieren, ohne Deinstallation. Eigene CSVs, vorhandene Markierungen, Einstellungen und vorhandene Fortschrittsdaten vor/nach der Installation vergleichen.
3. Echten PackageInstaller-/Berechtigungsablauf sowie Bedienung mit Bildschirmtastatur und langem Druck auf einem Gerät prüfen; vollständiger Ablauf auch in `docs/UPDATE_TESTPLAN.md`.
4. Merge und Veröffentlichung ausschließlich nach Willis Freigabe. Die bestehende Workflow-Vorlage wurde nicht aktiviert oder ausgeführt.

## Geänderte Dateien

| Datei | Änderung |
| --- | --- |
| `assets/navigation/categories.json` | Datenbasierte Fachkategorien und Schlagwörter |
| `lib/core/topic_catalog.dart` | Zuordnung und normalisierte Suche |
| `lib/state/deck_navigation_store.dart` | Zusätzliche Navigationspräferenzen |
| `lib/state/deck_controller.dart` | Navigation, Verlauf, Favoriten und Suchindex |
| `lib/data/repositories/deck_repository.dart` | Lesender Index über Fragen und Antworten |
| `lib/ui/screens/topic_picker_screen.dart` | Accordion, Suche und Schnellfilter |
| `lib/ui/widgets/topic_tile.dart` | Umgebrochene Namen und Kartenanzahl unter dem Titel |
| `lib/ui/widgets/topic_mark_sheet.dart` | Bestehende Markierungen plus Kategorieauswahl; scrollbar |
| `lib/core/app_info.dart` | Version 1.7.13, Build 24 |
| `pubspec.yaml` | Version, Kategorie-Asset und reine Testabhängigkeit |
| `pubspec.lock` | Fünf zusätzliche Pakete für SQLite-Tests |
| `test/topic_catalog_test.dart` | Kategorien und Suchnormalisierung |
| `test/deck_navigation_store_test.dart` | Persistenz und bestehende Präferenzen |
| `test/deck_navigation_persistence_test.dart` | Echte SQLite-Wiederherstellung |
| `test/topic_picker_test.dart` | Bedienung und responsive Darstellung |
| `test/widget_test.dart` | Erwartete Versionsmetadaten angepasst |
| `README.md` | Bedienung und Konfiguration |
| `Versionshinweise.txt` | Geplante Versionshinweise |
| `docs/NAVIGATION_QA.md` | Dieser Prüfbericht |
