# TECH//DECK

Karteikarten-App für die Prüfungsvorbereitung von Fachinformatikern.

**Entwickler:** Willi Gering

## Idee

Mitgeliefert sind 16 IT-Themen mit je 50 Karten (800 insgesamt). Zusätzlich kann eine CSV-Datei als eigenes Thema importiert werden: Der Dateiname (ohne `.csv`) wird zum Themennamen. Die Reihenfolge der importierten Dateien ist die Reihenfolge der Themen — ohne alphabetische Umsortierung.

## Funktionen

- CSV-Import (UTF-8, Umlaute, Quotes, große Dateien)
- Themenübersicht in Importreihenfolge
- Lernmodus mit echter Card-Flip-Animation
- Quiz mit 10 / 15 / 20 Fragen: eine richtige und drei **gespeicherte**, zur Frage passende falsche Antworten derselben Karte
- Karten ohne fachlich passende Distraktoren erscheinen nicht im Quiz, bleiben aber im Lernmodus
- Lernmodus zeigt nur die korrekte Lösung, keine Distraktoren
- Optional: KI-Distraktoren über ein eigenes Backend (SpaceXAI), nie mit Schlüssel in der App
- Lokale Statistiken, vollständig offline

## Eigene Karteien erstellen

Eigene Lernkarten können als CSV-Datei importiert werden. Der Dateiname ohne `.csv` wird in TECH//DECK automatisch zum Themennamen.

Empfohlenes Format:

```csv
Frage;Antwort;FalscheAntwort1;FalscheAntwort2;FalscheAntwort3
Was macht DNS?;DNS übersetzt Domainnamen in IP-Adressen.;DNS vergibt automatisch IP-Adressen.;DNS verschlüsselt Netzwerkverkehr.;DNS verbindet zwei Netzwerke.
Was macht DHCP?;DHCP vergibt automatisch Netzwerkkonfigurationen an Clients.;DHCP löst Domainnamen auf.;DHCP verschlüsselt Webseiten.;DHCP prüft Dateien auf Schadsoftware.
```

Die drei falschen Antworten sind für den Quizmodus wichtig. Sie sollten fachlich zum jeweiligen Thema passen und plausibel sein. Karten ohne drei geeignete gespeicherte Falschantworten bleiben im Lernmodus nutzbar, können aber im Quiz fehlen.

TECH//DECK erkennt neben `;` auch Komma, Tab und `|` als Trennzeichen. UTF-8 wird empfohlen. Felder mit dem verwendeten Trennzeichen oder Zeilenumbrüchen sollten in doppelte Anführungszeichen gesetzt werden.

### Karteien mit KI erstellen

Mit folgendem Prompt können ChatGPT oder andere KI-Tools eine direkt importierbare Kartei erzeugen:

```text
Erstelle eine Lernkartei für TECH//DECK zum Thema [THEMA] mit [ANZAHL] Karten.

Gib ausschließlich den Inhalt einer CSV-Datei aus. Keine Erklärung, keine Markdown-Codeblöcke und keinen zusätzlichen Text.

Verwende exakt diese Spalten:
Frage;Antwort;FalscheAntwort1;FalscheAntwort2;FalscheAntwort3

Regeln:
- Jede Zeile enthält genau eine Lernkarte.
- Die Fragen müssen eindeutig und fachlich korrekt sein.
- Die richtige Antwort soll kurz, verständlich und vollständig sein.
- Erstelle zu jeder Frage genau drei plausible, aber eindeutig falsche Antworten.
- Die falschen Antworten müssen fachlich zur jeweiligen Frage passen. Keine zufälligen oder offensichtlich unsinnigen Antworten.
- Die falschen Antworten dürfen nicht nur minimale Umformulierungen voneinander sein.
- Verwende keine Multiple-Choice-Buchstaben wie A, B, C oder D.
- Verwende ein Semikolon als Trennzeichen.
- Wenn ein Feld selbst ein Semikolon oder einen Zeilenumbruch enthält, setze das gesamte Feld in doppelte Anführungszeichen.
- Wiederhole keine Fragen.
- Verwende UTF-8 und normale deutsche Umlaute.

Beginne direkt mit der Kopfzeile.
```

Die Ausgabe anschließend als `Themenname.csv` in UTF-8 speichern und über den CSV-Import von TECH//DECK auswählen.

### Kleine Bash-Helfer

CSV-Datei schnell anlegen:

```bash
cat > Netzwerk.csv <<'EOF'
Frage;Antwort;FalscheAntwort1;FalscheAntwort2;FalscheAntwort3
Was macht DNS?;DNS übersetzt Domainnamen in IP-Adressen.;DNS vergibt automatisch IP-Adressen.;DNS verschlüsselt Netzwerkverkehr.;DNS verbindet zwei Netzwerke.
EOF
```

Anzahl der Karten prüfen (Kopfzeile wird nicht mitgezählt):

```bash
echo "$(( $(wc -l < Netzwerk.csv) - 1 )) Karten"
```

Datei auf UTF-8 prüfen:

```bash
file -i Netzwerk.csv
```

## Starten

```bash
cd "D:\APP DEV GROK\TECH-DECK"
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
