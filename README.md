# TECH//DECK

Karteikarten-App für die Prüfungsvorbereitung von Fachinformatikern.

**Entwickler:** Willi Gering

## Idee

Mitgeliefert sind 16 IT-Themen mit je 50 Karten (800 insgesamt). Zusätzlich kann eine CSV-Datei als eigenes Thema importiert werden: Der Dateiname (ohne `.csv`) wird zum Themennamen. Die Reihenfolge der importierten Dateien ist die Reihenfolge der Themen — ohne alphabetische Umsortierung.

## Funktionen

- CSV-Import (UTF-8, Umlaute, Quotes, große Dateien)
- Themenübersicht in Importreihenfolge
- Lernmodus mit echter Card-Flip-Animation
- Quiz mit 10 / 15 / 20 Fragen: eine richtige und drei **gespeicherte** falsche Antworten derselben Karte
- Lernmodus zeigt nur die korrekte Lösung, keine Distraktoren
- Optional: KI-Distraktoren über ein eigenes Backend (SpaceXAI), nie mit Schlüssel in der App
- Lokale Statistiken, vollständig offline

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
