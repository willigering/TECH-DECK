# TECH//DECK

Karteikarten-App zum Lernen, Wiederholen und Vertiefen.

**Entwickler:** Willi Gering

## Idee

Mitgeliefert sind 16 IT-Themen mit je 50 Karten (800 insgesamt). Zusätzlich kann eine CSV-Datei als eigenes Thema importiert werden: Der Dateiname (ohne `.csv`) wird zum Themennamen. Die Reihenfolge der importierten Dateien ist die Reihenfolge der Themen — ohne alphabetische Umsortierung.

## Funktionen

- CSV-Import (UTF-8, Umlaute, Quotes, große Dateien)
- Themenübersicht in Importreihenfolge
- Lernmodus mit echter Card-Flip-Animation
- Quizmodus **noch in Entwicklung**
- Lernmodus zeigt nur die korrekte Lösung, keine Distraktoren
- Optional: KI-Distraktoren über ein eigenes Backend (SpaceXAI), nie mit Schlüssel in der App
- Lokale Statistiken, vollständig offline

## Eigene Karteien erstellen

Eigene Lernkarten können als CSV-Datei importiert werden. Der Dateiname ohne `.csv` wird in TECH//DECK automatisch zum Themennamen.

Empfohlenes Format:

```csv
Frage;Antwort
Was macht DNS?;DNS übersetzt Domainnamen in IP-Adressen.
Was macht DHCP?;DHCP vergibt automatisch Netzwerkkonfigurationen an Clients.
```

Für den Lernmodus werden nur Frage und Antwort benötigt. Der Quizmodus befindet sich noch in Entwicklung; deshalb müssen beim Erstellen eigener Karteien derzeit keine falschen Antworten angegeben werden.

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
- Prüfe vor der Ausgabe gedanklich jede Karte auf fachliche Richtigkeit, Eindeutigkeit und Lernwert.
- Verteile die Karten sinnvoll über das gesamte Thema, statt viele Karten zum selben Teilbereich zu erzeugen.
- Falls [THEMA] zu umfangreich für [ANZAHL] Karten ist, priorisiere das prüfungs- und praxisrelevanteste Wissen.

Ausgabeformat:
Gib ausschließlich eine importierbare CSV-Datei aus.
Keine Einleitung, keine Erklärung, keine Markdown-Codeblöcke und keinen zusätzlichen Text.

Verwende exakt diese Kopfzeile:
Frage;Antwort

CSV-Regeln:
- Jede Zeile enthält genau eine Lernkarte.
- Verwende ein Semikolon als Trennzeichen.
- Wenn ein Feld ein Semikolon, doppelte Anführungszeichen oder einen Zeilenumbruch enthält, setze das gesamte Feld in doppelte Anführungszeichen und maskiere enthaltene doppelte Anführungszeichen CSV-konform.
- Verwende UTF-8 und normale deutsche Umlaute.

Beginne direkt mit der Kopfzeile.
```

Die Ausgabe anschließend als `Themenname.csv` in UTF-8 speichern und über den CSV-Import von TECH//DECK auswählen.

### Eigenes Lernmaterial mit NotebookLM

Du möchtest lieber mit deinen eigenen Unterlagen lernen? Auch dafür eignet sich [NotebookLM](https://notebooklm.google.com/). Dort kannst du eigene Quellen und Unterrichtsmaterialien hinzufügen und daraus Lernkarten erstellen lassen – von ordentlich aufbereiteten PDFs und Skripten bis hin zum wirren Gekritzel des Dozenten. :)

NotebookLM kann die erzeugten Lernkarten als CSV herunterladen. Prüfe die Datei anschließend kurz und passe sie bei Bedarf an das TECH//DECK-Format `Frage;Antwort` an, bevor du sie importierst.


## Starten

```bash
flutter pub get
flutter run
```

Release-APK:

```bash
flutter build apk --release
```

## KI-Distraktoren (optional)

Die App ruft **kein** xAI direkt auf. Ablauf: App → `backend/` → SpaceXAI (`https://api.x.ai/v1`).

Einrichtung: siehe `backend/README.md`.

Umgebungsvariablen (nur Backend, Datei `backend/.env`):

| Variable | Zweck |
|---|---|
| `XAI_API_KEY` | SpaceXAI-Schlüssel, **nie** in der App |
| `XAI_MODEL` | Standard `grok-4.6` |
| `XAI_BASE_URL` | Standard `https://api.x.ai/v1` |
| `TECHDECK_API_TOKEN` | optional, App muss denselben Wert senden |
| `RATE_LIMIT_PER_MINUTE` | Standard 30 |

In der App unter Einstellungen die Backend-URL setzen, z. B. `http://10.0.2.2:8787` im Emulator.

Ohne Backend bleiben Lernen und gespeicherte Quizkarten offline nutzbar. KI wird nur nach ausdrücklicher Bestätigung im Import ausgeführt.
