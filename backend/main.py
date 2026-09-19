"""TECH//DECK KI-Backend. Ruft SpaceXAI (xAI) auf. Der API-Schlüssel bleibt nur hier."""

from __future__ import annotations

import os
import time
from collections import defaultdict, deque
from typing import Any

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator

load_dotenv()

XAI_API_KEY = os.getenv("XAI_API_KEY", "").strip()
XAI_MODEL = os.getenv("XAI_MODEL", "grok-4.6").strip() or "grok-4.6"
XAI_BASE_URL = os.getenv("XAI_BASE_URL", "https://api.x.ai/v1").rstrip("/")
APP_TOKEN = os.getenv("TECHDECK_API_TOKEN", "").strip()
RATE_LIMIT = int(os.getenv("RATE_LIMIT_PER_MINUTE", "30"))

SYSTEM_PROMPT = """Du erzeugst genau drei FALSCHE Antworten für EINE einzelne IHK-Quizfrage (Fachinformatiker Systemintegration).

Regeln:
- Jede Falschantwort ist eine direkte, plausible Antwort auf GENAU DIESE Frage, aber fachlich falsch.
- Gleiches Format wie die richtige Antwort (Zahl+Einheit, Begriff oder kurzer Satz).
- Keine Definitionen anderer Begriffe. Keine Antworten aus fremden Themen.
- Keine allgemeinen Floskeln (Passwörter, Backup, Stromversorgung, mündliche Absprache).
- Keine Duplikate, keine leeren Texte, keine Wiederholung der richtigen Antwort.
- Verrate die richtige Lösung nicht durch Formulierungen wie „nicht 32 Bit“.
- Arbeite ausschließlich mit der gelieferten Frage und richtigen Antwort.
- Nur JSON gemäß Schema."""

SCHEMA = {
    "type": "object",
    "properties": {
        "wrongAnswers": {
            "type": "array",
            "minItems": 3,
            "maxItems": 3,
            "items": {"type": "string", "minLength": 1, "maxLength": 400},
        }
    },
    "required": ["wrongAnswers"],
    "additionalProperties": False,
}

app = FastAPI(title="TECH//DECK KI-Backend", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)

_hits: dict[str, deque[float]] = defaultdict(deque)


class DistractorRequest(BaseModel):
    question: str = Field(min_length=1, max_length=2000)
    correctAnswer: str = Field(min_length=1, max_length=2000)
    existingWrongAnswers: list[str] = Field(default_factory=list, max_length=3)

    @field_validator("question", "correctAnswer")
    @classmethod
    def strip_text(cls, value: str) -> str:
        text = value.strip()
        if not text:
            raise ValueError("darf nicht leer sein")
        return text


class DistractorResponse(BaseModel):
    wrongAnswers: list[str]


def _client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def _rate_limit(ip: str) -> None:
    now = time.time()
    window = _hits[ip]
    while window and now - window[0] > 60:
        window.popleft()
    if len(window) >= RATE_LIMIT:
        raise HTTPException(status_code=429, detail="Anfragelimit erreicht. Bitte später erneut versuchen.")
    window.append(now)


def _authorize(authorization: str | None) -> None:
    if not APP_TOKEN:
        return
    expected = f"Bearer {APP_TOKEN}"
    if authorization != expected:
        raise HTTPException(status_code=401, detail="Ungültiges App-Token.")


def _normalize(text: str) -> str:
    return " ".join(text.lower().split())


_JUNK = (
    "speichert ausschließlich passw",
    "vollständiges backup aller dateien",
    "mündliche absprache",
    "stromversorgung eines rechners",
    "löscht dateien und einstellungen ohne nachfrage",
)


def validate_wrong_answers(raw: list[Any], correct: str) -> list[str]:
    if not isinstance(raw, list):
        raise HTTPException(status_code=422, detail="wrongAnswers muss eine Liste sein.")
    if len(raw) != 3:
        raise HTTPException(status_code=422, detail="Es müssen genau drei falsche Antworten sein.")
    values = [str(item).strip() for item in raw]
    if any(not item for item in values):
        raise HTTPException(status_code=422, detail="Leere falsche Antworten sind unzulässig.")
    seen = {_normalize(correct)}
    for item in values:
        if len(item) > 400:
            raise HTTPException(status_code=422, detail="Eine Antwort ist zu lang.")
        key = _normalize(item)
        if key in seen:
            raise HTTPException(status_code=422, detail="Antworten dürfen nicht doppelt vorkommen.")
        low = item.lower()
        if any(marker in low for marker in _JUNK):
            raise HTTPException(
                status_code=422,
                detail="Eine Falschantwort ist fachfremd und wurde verworfen.",
            )
        seen.add(key)
    return values


@app.get("/health")
def health() -> dict[str, Any]:
    return {"ok": True, "model": XAI_MODEL, "keyConfigured": bool(XAI_API_KEY)}


@app.post("/v1/distractors", response_model=DistractorResponse)
async def create_distractors(
    body: DistractorRequest,
    request: Request,
    authorization: str | None = Header(default=None),
) -> DistractorResponse:
    _authorize(authorization)
    _rate_limit(_client_ip(request))
    if not XAI_API_KEY:
        raise HTTPException(status_code=503, detail="XAI_API_KEY ist auf dem Server nicht gesetzt.")

    user = (
        f"Frage: {body.question}\n"
        f"Richtige Antwort: {body.correctAnswer}\n"
        "Erzeuge drei fachlich falsche, aber zur Frage passende Alternativen."
    )
    if body.existingWrongAnswers:
        user += "\nVorhandene Vorschläge zum Prüfen/Ersetzen: " + " | ".join(
            item.strip() for item in body.existingWrongAnswers if item.strip()
        )

    payload = {
        "model": XAI_MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user},
        ],
        "temperature": 0.4,
        "response_format": {
            "type": "json_schema",
            "json_schema": {"name": "distractors", "strict": True, "schema": SCHEMA},
        },
    }

    try:
        async with httpx.AsyncClient(timeout=40.0) as client:
            response = await client.post(
                f"{XAI_BASE_URL}/chat/completions",
                headers={
                    "Authorization": f"Bearer {XAI_API_KEY}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
    except httpx.HTTPError:
        raise HTTPException(status_code=502, detail="Die KI-API ist nicht erreichbar.") from None

    if response.status_code >= 400:
        raise HTTPException(status_code=502, detail="Die KI-API hat die Anfrage abgelehnt.")

    try:
        data = response.json()
        content = data["choices"][0]["message"]["content"]
        parsed = DistractorResponse.model_validate_json(content)
    except Exception:
        raise HTTPException(status_code=502, detail="Ungültige KI-Antwort.") from None

    wrongs = validate_wrong_answers(parsed.wrongAnswers, body.correctAnswer)
    return DistractorResponse(wrongAnswers=wrongs)
