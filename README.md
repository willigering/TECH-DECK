# TECH//DECK

Karteikarten-App zum Lernen, Wiederholen und Vertiefen.

**Entwickler:** Willi Gering

## Idee

Mitgeliefert sind **22 Decks** mit unterschiedlichen Kartenanzahlen. Dazu gehören IT-Grundlagen, Hardware, Betriebssysteme, Netzwerke, Windows- und Linux-Terminal, IT-Abkürzungen, IHK-Prüfung und Datenschutz. Zusätzlich kann eine CSV-Datei als eigenes Thema importiert werden: Der Dateiname (ohne `.csv`) wird zum Themennamen. Die Reihenfolge der importierten Dateien ist die Reihenfolge der Themen — ohne alphabetische Umsortierung.

## Funktionen

- Ausschließlich CSV-Import (UTF-8, Umlaute und Anführungszeichen); mehrere Dateien gleichzeitig
- Aufklappbare Fachkategorien mit Kartenanzahlen; innerhalb der Kategorien bleibt die bisherige Reihenfolge erhalten
- Suche nach Kategorien, Decknamen, Dateinamen sowie Begriffen in Fragen und Antworten
- Schnellzugriffe für Favoriten (Lesezeichen), die fünf zuletzt geöffneten Decks und wichtige Decks
- Fachkategorie bei Bedarf per Langdruck auswählen; automatische Regeln in `assets/navigation/categories.json`
- Lernmodus mit echter Card-Flip-Animation
- ~~Quizmodus~~ — **in Entwicklung, aktuell nicht in der App verfügbar**
- Lernmodus zeigt nur die korrekte Lösung, keine Distraktoren
- ~~KI-Distraktoren~~ — **in Entwicklung, aktuell nicht in der App verfügbar**
- Lernkarten lokal auf dem Gerät, ohne Konto nutzbar
- Themen per langem Druck farbig und als wichtig markieren
- Drei Designs: Dark/Gold, Light/Gold und Midnight/Silver
- Statischer Platinenhintergrund ohne laufende Animation
- Neue mitgelieferte Decks sind orange und mit „Neu“ gekennzeichnet. Die Markierung verschwindet beim ersten Öffnen, beim Farbwechsel, beim Markieren als wichtig oder spätestens sieben Tage nach dem ersten Start der Version.

## Kategorienavigation

Unter **Lernen → Thema wählen** öffnet ein Tipp auf eine Fachkategorie die enthaltenen Kartensätze; ein weiterer Tipp klappt sie ein. Die Überschrift zeigt Kartensatz- und Kartenanzahl, jedes Deck seine eigene Kartenanzahl. Lange Namen werden umgebrochen. Eine Suche öffnet passende Gruppen automatisch; nach dem Löschen der Suche gilt wieder der zuvor gewählte Aufklappzustand. Während einer Suche beziehen sich die angezeigten Gruppenzahlen auf die Treffer.

**Favoriten** werden über das Lesezeichen am Deck gesetzt. **Wichtig** bleibt die bestehende Sternmarkierung im Langdruck-Menü. **Zuletzt** zeigt bis zu fünf erfolgreich geöffnete Decks, neuestes zuerst; diese Liste beginnt mit der ersten Nutzung dieser Navigation. Alle Schnellfilter berücksichtigen auch den Suchtext.

Die automatische Zuordnung prüft die Schlagwörter in `assets/navigation/categories.json` in ihrer Reihenfolge. Nicht erkannte Namen landen unter **Weitere Themen**. Im Langdruck-Menü lässt sich eine Kategorie fest zuweisen oder wieder auf **Automatisch zuordnen** zurücksetzen. Neue Fachgebiete und Schlagwörter erfordern nur eine Änderung der Konfiguration, keine Anpassung des Navigationswidgets. Bestehende Deck-IDs und Namen ändern sich dabei nicht.

Favoriten, Kategoriezuordnungen und Verlauf liegen ausschließlich im zusätzlichen SharedPreferences-Eintrag `deck_navigation_v1`. Bestehende Farb- und Wichtig-Markierungen bleiben in SQLite; Datenbankschema und gebündelte Inhaltsrevision bleiben unverändert. Ein Downgrade auf die bisherige Oberfläche ignoriert den zusätzlichen Einstellungseintrag.

## Eigene Karteien erstellen

Eigene Lernkarten können als CSV-Datei importiert werden. Der Dateiname ohne `.csv` wird in TECH//DECK automatisch zum Themennamen.

Empfohlenes Format:

```csv
Frage;Antwort
Was macht DNS?;DNS übersetzt Domainnamen in IP-Adressen.
Was macht DHCP?;DHCP vergibt automatisch Netzwerkkonfigurationen an Clients.
```

Für den Lernmodus werden nur Frage und Antwort benötigt. **Quizmodus und KI-Distraktoren befinden sich noch in Entwicklung und sind aktuell nicht in der App implementiert.** Deshalb müssen beim Erstellen eigener Karteien keine falschen Antworten angegeben werden.

TECH//DECK erkennt neben `;` auch Komma, Tab und `|` als Trennzeichen. UTF-8 wird empfohlen. Felder mit dem verwendeten Trennzeichen oder Zeilenumbrüchen sollten in doppelte Anführungszeichen gesetzt werden.

### Karteien mit KI erstellen

Mit ChatGPT oder einem anderen KI-Tool kannst du komplette Karteien für TECH//DECK erzeugen. Für möglichst hochwertige Karten empfiehlt sich dieser ausführlichere Prompt:

```text
Erstelle eine hochwertige Lernkartei für TECH//DECK zum Thema [THEMA] mit [ANZAHL] Karten.

Ziel:
Die Karten sollen nicht nur Begriffe abfragen, sondern echtes Verständnis fördern und sich zur Prüfungsvorbereitung eignen. Decke die wichtigsten Grundlagen, Zusammenhänge, Funktionen, Unterschiede und typische Praxisbeispiele des Themas ab.

Qualitätsregeln:
- Jede Karte behandelt genau einen klaren Lerninhalt.
- Formuliere eindeutige Fragen, die ohne zusätzlichen Kontext verständlich sind.
- Antworten müssen fachlich korrekt, präzise und möglichst kurz sein.
- Erkläre so einfach wie möglich, aber so ausführlich wie nötig.
- Bevorzuge Verständnisfragen wie „Warum…?“, „Wie funktioniert…?“, „Was ist der Unterschied…?“ oder „Wofür wird… verwendet?“, wenn sie zum Thema passen.
- Ergänze wichtige Definitionen, Abkürzungen und typische Prüfungsfragen.
- Berücksichtige auch praktische Zusammenhänge und typische Anwendungsfälle.
- Vermeide doppelte oder nahezu identische Fragen.
- Vermeide Fragen, deren Antwort bereits in der Frage steckt.
- Vermeide unnötige Detailfragen, exotisches Spezialwissen und Fangfragen.
- Verwende keine Multiple-Choice-Antworten und erzeuge keine falschen Antworten.
- Prüfe jede fachliche Aussage vor der Ausgabe auf Richtigkeit. Erfinde keine Fakten, Fachbegriffe, Standards, Befehle, Grenzwerte oder Definitionen.
- Recherchiere bei Themen, die sich ändern können, vor der Kartenerstellung den aktuellen Stand anhand verlässlicher und möglichst offizieller Quellen. Dazu gehören insbesondere Software, Betriebssysteme, IT-Standards, Protokolle, Gesetze, Richtlinien, Produktversionen und technische Empfehlungen.
- Bevorzuge Primärquellen und offizielle Dokumentationen gegenüber Foren, Blogs oder ungeprüften Zusammenfassungen.
- Verwende bei zeitabhängigen Aussagen den aktuell gültigen Stand. Wenn ältere und aktuelle Regelungen oder Standards voneinander abweichen, formuliere die Frage so, dass eindeutig erkennbar ist, auf welchen Stand sie sich bezieht.
- Wenn eine Information nicht zuverlässig verifiziert werden kann, erstelle daraus keine Lernkarte. Rate nicht und fülle Wissenslücken nicht mit plausibel klingenden Annahmen.
- Prüfe vor der Ausgabe jede Karte noch einmal auf fachliche Richtigkeit, Aktualität, Eindeutigkeit und Lernwert.
- Verteile die Karten sinnvoll über das gesamte Thema, statt viele Karten zum selben Teilbereich zu erzeugen.
- Falls [THEMA] zu umfangreich für [ANZAHL] Karten ist, priorisiere das prüfungs- und praxisrelevanteste Wissen.

Ausgabeformat – zwingend:
- Das einzige Ergebnis deiner Antwort muss der fertige CSV-Inhalt sein.
- Gib keine Einleitung, Erklärung, Zusammenfassung, Quellenliste oder sonstigen Begleittext aus.
- Verwende keinen Markdown-Codeblock und keine ```-Markierungen.
- Recherchiere und verifiziere notwendige Informationen vor der Ausgabe, gib die Recherche selbst aber nicht zusätzlich aus.
- Die erste Zeile der Antwort muss exakt `Frage;Antwort` lauten.
- Danach folgen ausschließlich die Lernkarten als CSV-Zeilen.
- Erzeuge exakt [ANZAHL] Lernkarten zusätzlich zur Kopfzeile.
- Die Ausgabe muss direkt als `.csv` gespeichert und in TECH//DECK importiert werden können.

CSV-Regeln:
- Jede Zeile enthält genau eine Lernkarte.
- Verwende ein Semikolon als Trennzeichen.
- Wenn ein Feld ein Semikolon, doppelte Anführungszeichen oder einen Zeilenumbruch enthält, setze das gesamte Feld in doppelte Anführungszeichen und maskiere enthaltene doppelte Anführungszeichen CSV-konform.
- Verwende UTF-8 und normale deutsche Umlaute.

WICHTIG: Antworte ausschließlich mit dem CSV-Inhalt. Das erste Zeichen deiner Antwort muss zur Kopfzeile `Frage;Antwort` gehören. Nach der letzten CSV-Zeile darf kein Kommentar oder weiterer Text folgen.
```

Die Ausgabe anschließend als `Themenname.csv` in UTF-8 speichern und über den CSV-Import von TECH//DECK auswählen.

### Eigenes Lernmaterial mit NotebookLM

Du möchtest lieber mit deinen eigenen Unterlagen lernen? Auch dafür eignet sich [NotebookLM](https://notebooklm.google.com/). Dort kannst du eigene Quellen und Unterrichtsmaterialien hinzufügen und daraus Lernkarten erstellen lassen – von ordentlich aufbereiteten PDFs und Skripten bis hin zum wirren Gekritzel des Dozenten. :)

NotebookLM kann die erzeugten Lernkarten als CSV herunterladen. Prüfe die Datei anschließend kurz und passe sie bei Bedarf an das TECH//DECK-Format `Frage;Antwort` an, bevor du sie importierst.


## Aktuelle Version

**1.7.13+24**

## Starten

```bash
flutter pub get
flutter run
```

Nach Änderungen auf GitHub zunächst `git pull origin main` ausführen, dann `flutter pub get`.

Release-APK:

```bash
flutter build apk --release
```

Die APK liegt unter `build/app/outputs/flutter-apk/`. Zusätzlich zur Flutter-Standarddatei entsteht automatisch `TECH-DECK-<Version>+<Buildnummer>.apk`.

## ~~KI-Distraktoren~~ — In Entwicklung

> **Noch nicht in TECH//DECK implementiert.** Diese Funktion ist für eine zukünftige Version vorgesehen. Der aktuelle Lernmodus benötigt ausschließlich Frage und Antwort.

## Veröffentlichung und Updates

TECH//DECK wird im Google Play Store veröffentlicht. Updates werden über den Play Store verteilt. Die App enthält keine GitHub-Updateprüfung, keinen APK-Download und keinen eigenen Installer mehr.

### Versionsverwaltung

Für jeden Release **beide** Stellen anheben, `versionCode` (Zahl hinter `+`) immer um mindestens 1:

- `pubspec.yaml`: `version: 1.7.13+24`
- `lib/core/app_info.dart`: `version = '1.7.13'`, `buildNumber = 24`
- `Versionshinweise.txt`: neuer Abschnitt `v1.7.13 (Build 24) - Datum` (wird als Release Notes übernommen)

Der Workflow bricht ab, wenn `pubspec.yaml` und `AppInfo` nicht übereinstimmen.

### Signierung (wichtig)

**Schlüsselwechsel ab 1.7.12:** Bis 1.7.11+22 wurden die APKs mit dem lokalen Android-Debug-Schlüssel signiert (`ace2efc2…2e34`). Dieser Schlüssel war nicht mehr verfügbar. Ab **1.7.13+24** wird mit dem dauerhaften Release-Schlüssel `techdeck-release` signiert:

```
CN=Willi Gering, O=TECH//DECK, C=DE · RSA 4096 · Alias techdeck
Zertifikat SHA-256: 0cea186bcac2a7b5874ede5d5bdf9dc4e8ed5ba876d6da7ec567278b07ee754d
```

**Einmalige Neuinstallation:** Android akzeptiert 1.7.12 nicht als Update über 1.7.11 (anderer Schlüssel). Nutzer müssen 1.7.11 **einmalig deinstallieren** und 1.7.12 neu installieren. Dabei gehen lokale Daten verloren (importierte CSV-Karteien, Lernfortschritt, Markierungen, Einstellungen) – eigene CSV-Dateien vorher sichern. Der frühere GitHub-In-App-Updater wurde für die Play-Store-Veröffentlichung entfernt.

- Release-Builds **schlagen fehl**, wenn kein Release-Schlüssel konfiguriert ist; es gibt keinen Debug-Fallback mehr.
- Lokal: `android/key.properties` (git-ignoriert) mit `storeFile=`, `storePassword=`, `keyAlias=`, `keyPassword=`.
- Keystore und Passwörter sicher **offline sichern** (Verlust = erneute Zwangs-Neuinstallation für alle Nutzer). Niemals committen.

### Erforderliche GitHub Secrets / Variablen

| Name | Art | Inhalt |
| --- | --- | --- |
| `TECHDECK_KEYSTORE_BASE64` | Secret | `base64 -w0 techdeck-release.jks` |
| `TECHDECK_KEYSTORE_PASSWORD` | Secret | Keystore-Passwort |
| `TECHDECK_KEY_ALIAS` | Secret | Alias |
| `TECHDECK_KEY_PASSWORD` | Secret | Key-Passwort |
| `TECHDECK_SIGNING_CERT_SHA256` | Variable | `0cea186bcac2a7b5874ede5d5bdf9dc4e8ed5ba876d6da7ec567278b07ee754d` |

### Play-Store-Build

1. Version und Buildnummer anheben und die Release-Signierung konfigurieren (siehe oben).
2. `flutter pub get`, `flutter analyze` und `flutter test` ausführen.
3. Mit `flutter build appbundle --release` ein signiertes Android App Bundle erstellen.
4. `build/app/outputs/bundle/release/app-release.aab` in der Play Console hochladen und über den gewünschten Test- oder Produktions-Track veröffentlichen.

Der vorhandene manuelle GitHub-APK-Build bleibt für interne Builds erhalten. Seine Release-Metadaten werden von der App nicht mehr abgefragt.

## Halloween-Hintergrund

Vom 24. bis 31. Oktober zeigt der Startbildschirm jährlich Lumi mit Hexenhut und Kürbis als Hintergrund. Am 1. November kehrt automatisch der normale Hintergrund zurück, auch bei App-Rückkehr aus dem Hintergrund. Logo, Texte, Buttons und Navigation behalten ihre bisherigen Positionen und Funktionen. Die Grafik enthält keine gezeichneten Bedienelemente.
