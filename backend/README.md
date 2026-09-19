# TECH//DECK KI-Backend

Die Flutter-App ruft **dieses Backend** auf. Das Backend ruft SpaceXAI (xAI) auf.
Der Schlüssel `XAI_API_KEY` bleibt nur auf dem Server.

**Entwickler:** Willi Gering

## Einrichtung

1. Account und Schlüssel: https://console.x.ai
2. In diesem Ordner:

```bat
copy .env.example .env
```

3. In `.env` eintragen:

```
XAI_API_KEY=xai-...
XAI_MODEL=grok-4.6
```

4. Start:

```bat
start.bat
```

Der Dienst lauscht auf `http://0.0.0.0:8787`.

## App-URL

| Umgebung | Backend-URL in der App |
|---|---|
| Android-Emulator | `http://10.0.2.2:8787` |
| Windows-Desktop | `http://127.0.0.1:8787` |
| Echtes Handy im WLAN | `http://<PC-IP>:8787` |

Die URL steht unter **Einstellungen → KI-Backend**.

Optional `TECHDECK_API_TOKEN` setzen. Dann denselben Wert in der App eintragen.

## Endpunkte

- `GET /health`
- `POST /v1/distractors`  
  Body: `{ "question": "...", "correctAnswer": "...", "existingWrongAnswers": [] }`  
  Antwort: `{ "wrongAnswers": ["...", "...", "..."] }`  
  Die drei Werte gehören immer zur übergebenen Frage. Fachfremde Floskeln werden verworfen.

KI-Anfragen laufen nur bei ausdrücklicher Erstellung/Prüfung, nie im Quiz oder Lernmodus.

## Lokal testen

```bat
curl http://127.0.0.1:8787/health
```

```bat
curl -X POST http://127.0.0.1:8787/v1/distractors -H "Content-Type: application/json" -d "{\"question\":\"Wie viele Bits hat eine IPv4-Adresse?\",\"correctAnswer\":\"32 Bit\"}"
```
