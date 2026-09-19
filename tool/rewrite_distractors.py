#!/usr/bin/env python3
"""Schreibt thematische Falschantworten in die mitgelieferten CSVs."""
from __future__ import annotations

import csv
import pathlib
import re

DECKS = pathlib.Path(__file__).resolve().parents[1] / "assets" / "decks"

VERBS = {
    "ändert": ["löscht", "erstellt", "kopiert"],
    "verwaltet": ["ignoriert", "blockiert", "löscht"],
    "hält": ["löscht", "versteckt", "verschlüsselt"],
    "ermöglicht": ["verhindert", "blockiert", "beendet"],
    "verhindert": ["erzwingt", "erlaubt", "startet"],
    "erlaubt": ["verbietet", "löscht", "beendet"],
    "organisiert": ["löscht", "blockiert", "verschlüsselt"],
    "vermittelt": ["blockiert", "ignoriert", "ersetzt"],
    "erweitert": ["verringert", "blockiert", "löscht"],
    "erhöht": ["verringert", "beendet", "löscht"],
    "trennt": ["verbindet dauerhaft", "löscht", "kopiert"],
    "speichert": ["löscht", "ignoriert", "sendet unverschlüsselt"],
    "prüft": ["ignoriert", "löscht", "startet"],
    "startet": ["beendet", "löscht", "blockiert"],
    "besitzt": ["besitzt keine", "löscht", "versteckt"],
    "besteht": ["besteht nicht", "verhindert", "löscht"],
}

NOUNS = {
    "Zugriffsrechte": ["Dateinamen", "Besitzer", "Dateiinhalte"],
    "Besitzer": ["Dateinamen", "Zugriffsrechte", "Dateiendung"],
    "Dateien und Verzeichnissen": ["Benutzerkonten", "Netzwerkverbindungen", "Systemdiensten"],
    "Dateien und Verzeichnisse": ["Benutzerkonten", "Netzwerkverbindungen", "Systemdienste"],
    "Arbeitsspeicher": ["Druckerwarteschlange", "Bildschirmschoner", "Lautstärke"],
    "Netzanteil": ["Dateinamen", "Benutzerpasswort", "Druckername"],
    "Hostanteil": ["Dateiendung", "Bildschirmauflösung", "Lautstärke"],
}

NEARBY = [4, 7, 8, 16, 24, 32, 64, 128, 256, 512, 1024]
DEF_START = re.compile(
    r"^(?:Ein |Eine |Der |Die |Das )?"
    r"([A-Za-zÄÖÜäöü0-9][A-Za-zÄÖÜäöü0-9./+-]{1,40})"
    r"\s+(ist|sind|bedeutet|bezeichnet|umfasst|beschreibt|regelt|enthält)\b",
    re.I,
)
BEI_START = re.compile(r"^Bei ([A-Za-zÄÖÜäöü0-9./+-]+)\b", re.I)
CMD_ACTION = re.compile(
    r"^[A-Za-z][A-Za-z0-9._+-]{1,24}\s+"
    r"(ändert|erlaubt|setzt|startet|beendet|löscht|kopiert|zeigt|prüft|öffnet)",
    re.I,
)


def norm(s: str) -> str:
    return re.sub(r"\s+", " ", s.lower()).strip()


def extract_subject(question: str, answer: str) -> str:
    q = question.strip().rstrip("?").strip()
    patterns = [
        r"^Was macht (.+?)(?: unter| in\b| bei\b| auf\b| mit\b| für\b| durch\b|$)",
        r"^Was bewirkt (.+)$",
        r"^Wozu dient (.+)$",
        r"^Wofür steht(?: die Abkürzung)? (.+)$",
        r"^Was bedeutet (.+)$",
        r"^Was bezeichnet (.+)$",
        r"^Was ist der Unterschied zwischen (.+)$",
        r"^Was ist (?:ein |eine |der |die |das )?(.+)$",
        r"^Welche[rsn]? Hauptaufgaben hat (.+)$",
        r"^Welche[rsn]? Aufgabe hat (.+)$",
        r"^Wie viele .+?\b(?:eine |ein |der |die |das )?(.+)$",
    ]
    for p in patterns:
        m = re.search(p, q, re.I)
        if m:
            s = re.sub(r"^(ein|eine|der|die|das|den|dem|des)\s+", "", m.group(1).strip(), flags=re.I)
            return s.split(",")[0].strip()
    m = re.match(r"^([A-Za-zÄÖÜäöü0-9][A-Za-zÄÖÜäöü0-9./+-]{1,40})\b", answer.strip())
    return m.group(1) if m else " ".join(q.split()[:3])


def kind(question: str) -> str:
    s = question.lower()
    if s.startswith("was macht") or s.startswith("wozu dient") or s.startswith("was bewirkt") or "aufgabe hat" in s:
        return "action"
    if s.startswith("wie viele") or s.startswith("wieviel") or s.startswith("wie oft") or s.startswith("wie berechnet"):
        return "quantity"
    if s.startswith("was ist") or s.startswith("was bedeutet") or s.startswith("wofür steht") or s.startswith("was bezeichnet"):
        return "definition"
    return "other"


def mentions(text: str, subject: str) -> bool:
    hay = norm(text)
    needle = norm(subject)
    if not needle:
        return False
    parts = [w for w in needle.split() if len(w) >= 3]
    head = parts[0] if parts else needle
    return head in hay


def defines_other(text: str, subject: str) -> bool:
    m = DEF_START.search(text.strip())
    if m:
        return not mentions(m.group(1), subject)
    m = BEI_START.search(text.strip())
    if m:
        return not mentions(m.group(1), subject)
    return False


def thematic(candidate: str, correct: str, subject: str, qkind: str) -> bool:
    text = candidate.strip()
    if not text or norm(text) == norm(correct):
        return False
    if mentions(text, subject):
        return True
    if re.search(r"\d", correct) and re.search(r"\d", text):
        return True
    if defines_other(text, subject):
        return False
    if qkind == "definition":
        return False
    if qkind == "action" and CMD_ACTION.search(correct) and CMD_ACTION.search(text):
        return True
    return False


def numeric_variants(answer: str) -> list[str]:
    out = []
    for m in re.finditer(r"\d+", answer):
        n = int(m.group(0))
        vals = {n - 1, n + 1, n + 2, n * 2}
        if n > 2:
            vals.add(n - 2)
            if n % 2 == 0:
                vals.add(n // 2)
        vals.update(NEARBY)
        vals.discard(n)
        vals = {v for v in vals if v > 0}
        for v in sorted(vals):
            out.append(answer[: m.start()] + str(v) + answer[m.end() :])
    return out


def mutate(answer: str, mapping: dict[str, list[str]]) -> list[str]:
    out = []
    for src, dsts in mapping.items():
        if src in answer:
            for dst in dsts:
                out.append(answer.replace(src, dst, 1))
    return out


def templates(subject: str, qkind: str) -> list[str]:
    s = subject.strip()
    if not s:
        return []
    if qkind == "action":
        return [
            f"{s} löscht Dateien und Einstellungen ohne Nachfrage.",
            f"{s} startet alle Systemdienste neu.",
            f"{s} ändert den Rechnernamen.",
            f"{s} blockiert jede Anmeldung am System.",
        ]
    return [
        f"{s} speichert ausschließlich Passwörter und Zugangsdaten.",
        f"{s} ersetzt ein vollständiges Backup aller Dateien.",
        f"{s} ist nur eine mündliche Absprache ohne schriftliche Aufzeichnung.",
        f"{s} bezeichnet ausschließlich die Stromversorgung eines Rechners.",
    ]


def build_wrongs(question: str, answer: str, existing: list[str]) -> list[str]:
    subj = extract_subject(question, answer)
    qkind = kind(question)
    seen = {norm(answer)}
    wrongs: list[str] = []

    def add(raw: str) -> None:
        text = raw.strip()
        if not text or norm(text) in seen:
            return
        seen.add(norm(text))
        wrongs.append(text)

    for cand in existing:
        if len(wrongs) >= 3:
            break
        if thematic(cand, answer, subj, qkind):
            add(cand)
    generated = []
    if re.search(r"\d", answer):
        generated += numeric_variants(answer)
    if not (re.search(r"\d", answer) and len(answer) <= 48):
        generated += mutate(answer, VERBS)
        generated += mutate(answer, NOUNS)
        generated += templates(subj, qkind)
    for g in generated:
        if len(wrongs) >= 3:
            break
        add(g)
    if len(wrongs) < 3:
        raise SystemExit(f"zu wenig Distraktoren: {question}")
    return wrongs[:3]


def rewrite(path: pathlib.Path) -> None:
    text = path.read_text(encoding="utf-8-sig")
    rows = list(csv.reader(text.splitlines(), delimiter=";"))
    header, data = rows[0], rows[1:]
    out_rows = [header]
    for row in data:
        while len(row) < 5:
            row.append("")
        q, a, w1, w2, w3 = row[0], row[1], row[2], row[3], row[4]
        if not q.strip() or not a.strip():
            continue
        wrongs = build_wrongs(q, a, [w1, w2, w3])
        out_rows.append([q, a, *wrongs])
    buf = "\n".join(";".join(_csv_field(c) for c in r) for r in out_rows) + "\n"
    path.write_text("\ufeff" + buf, encoding="utf-8")


def _csv_field(value: str) -> str:
    if any(ch in value for ch in ";\"\n"):
        return '"' + value.replace('"', '""') + '"'
    return value


def main() -> None:
    files = sorted(DECKS.glob("*.csv"))
    for path in files:
        rewrite(path)
        print("ok", path.name)


if __name__ == "__main__":
    main()
