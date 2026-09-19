#!/usr/bin/env python3
"""Erzeugt karteneigene Falschantworten aus der richtigen Antwort.

Keine Antworten anderer Karten. Keine Passwort-/Backup-Schablonen.
Nur Mutationen der jeweiligen richtigen Antwort (Zahlen, Verben, Fachbegriffe).
"""
from __future__ import annotations

import csv
import pathlib
import re

DECKS = pathlib.Path(__file__).resolve().parents[1] / "assets" / "decks"

JUNK = re.compile(
    r"speichert ausschlie(?:ss|ß)lich passw|"
    r"vollst(?:ä|ae)ndiges backup aller dateien|"
    r"m(?:ü|ue)ndliche absprache|"
    r"stromversorgung eines rechners|"
    r"l(?:ö|oe)scht dateien und einstellungen ohne nachfrage|"
    r"startet alle systemdienste neu|"
    r"(?:ä|ae)ndert den rechnernamen|"
    r"blockiert jede anmeldung am system",
    re.I,
)

VERBS = [
    ("ermöglicht", "verhindert"),
    ("verhindert", "erzwingt"),
    ("erlaubt", "verbietet"),
    ("verbietet", "erlaubt"),
    ("übersetzt", "löscht"),
    ("trennt", "verbindet dauerhaft"),
    ("verbindet", "trennt"),
    ("speichert", "verwirft"),
    ("prüft", "ignoriert"),
    ("überwacht", "ignoriert"),
    ("zeichnet", "löscht"),
    ("vergibt", "entzieht"),
    ("verschlüsselt", "sendet unverschlüsselt"),
    ("startet", "beendet"),
    ("beendet", "startet"),
    ("erhöht", "verringert"),
    ("verringert", "erhöht"),
    ("erweitert", "verkleinert"),
    ("organisiert", "blockiert"),
    ("verwaltet", "ignoriert"),
    ("definiert", "ignoriert"),
    ("beschreibt", "verschweigt"),
    ("regelt", "hebt auf"),
    ("enthält", "enthält keine"),
    ("besitzt", "besitzt keine"),
    ("besteht aus", "besteht nicht aus"),
    ("besteht", "besteht nicht"),
    ("sendet", "blockiert"),
    ("empfängt", "verwirft"),
    ("leitet weiter", "verwirft"),
    ("ändert", "löscht"),
    ("kopiert", "löscht"),
    ("zeigt", "versteckt"),
    ("öffnet", "schließt"),
    ("wird verwendet", "wird nicht verwendet"),
    ("werden verwendet", "werden nicht verwendet"),
    ("dient", "dient nicht"),
    ("bezeichnet", "versteckt"),
    ("umfasst", "schließt aus"),
    ("grenzt", "vermischt"),
    ("stellt", "löscht"),
    ("sorgt", "verhindert"),
    ("liegt", "liegt nicht"),
    ("handelt", "handelt nicht"),
    ("führt", "blockiert"),
    ("verarbeitet", "verwirft"),
    ("berechnet", "schätzt nur"),
    ("steuert", "ignoriert"),
    ("erzeugt", "unterdrückt"),
    ("sichert", "verwirft"),
    ("sammelt", "verwirft"),
    ("identifiziert", "vermischt"),
    ("bewertet", "ignoriert"),
    ("dokumentiert", "verschweigt"),
    ("übergibt", "behält"),
    ("umgeht", "erzwingt"),
    ("legt fest", "hebt auf"),
    ("misst", "ignoriert"),
    ("überträgt", "blockiert"),
    ("speichert", "verwirft"),
]

SWAPS = [
    ("IPv4", "IPv6"),
    ("IPv6", "IPv4"),
    ("Layer 2", "Layer 3"),
    ("Layer 3", "Layer 2"),
    ("Schicht 2", "Schicht 3"),
    ("Schicht 3", "Schicht 2"),
    ("TCP", "UDP"),
    ("UDP", "TCP"),
    ("HTTP", "HTTPS"),
    ("HTTPS", "HTTP"),
    ("RAM", "ROM"),
    ("ROM", "RAM"),
    ("Switch", "Router"),
    ("Router", "Switch"),
    ("DNS", "DHCP"),
    ("DHCP", "DNS"),
    ("Client", "Server"),
    ("Server", "Client"),
    ("privat", "öffentlich"),
    ("öffentlich", "privat"),
    ("intern", "extern"),
    ("extern", "intern"),
    ("lokal", "global"),
    ("global", "lokal"),
    ("synchron", "asynchron"),
    ("asynchron", "synchron"),
    ("statisch", "dynamisch"),
    ("dynamisch", "statisch"),
    ("inkrementell", "differentiell"),
    ("differentiell", "inkrementell"),
    ("Vollbackup", "inkrementelles Backup"),
    ("verschlüsselt", "unverschlüsselt"),
    ("unverschlüsselt", "verschlüsselt"),
    ("IPv4-Adresse", "IPv6-Adresse"),
    ("IPv6-Adresse", "IPv4-Adresse"),
    ("32 Bit", "128 Bit"),
    ("128 Bit", "32 Bit"),
    ("7 Schichten", "4 Schichten"),
    ("MAC-Adresse", "IP-Adresse"),
    ("IP-Adresse", "MAC-Adresse"),
]

NEARBY = [2, 4, 7, 8, 16, 24, 32, 48, 64, 126, 128, 254, 256, 510, 512, 1024]


def norm(s: str) -> str:
    text = s.lower().replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")
    text = re.sub(r"[^a-z0-9./+\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def is_junk(text: str) -> bool:
    return bool(JUNK.search(text))


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
        r"^(?:Aus )?wie viele[n]? .+\b(?:eine |ein |der |die |das )(.+)$",
        r"^Erkläre (.+)$",
    ]
    for p in patterns:
        m = re.search(p, q, re.I)
        if m:
            s = re.sub(r"^(ein|eine|der|die|das|den|dem|des)\s+", "", m.group(1).strip(), flags=re.I)
            return s.split(",")[0].strip()
    m = re.match(r"^([A-Za-zÄÖÜäöü0-9][A-Za-zÄÖÜäöü0-9./+-]{1,40})\b", answer.strip())
    return m.group(1) if m else " ".join(q.split()[:3])


def _is_protected_number(answer: str, start: int, end: int) -> bool:
    prefix = answer[max(0, start - 3) : start]
    if re.search(r"IPv$", prefix, re.I):
        return True
    if start > 0 and answer[start - 1] in "./":
        return True
    if end < len(answer) and answer[end] in ".":
        return True
    return False


def numeric_variants(answer: str) -> list[str]:
    matches = list(re.finditer(r"\d+", answer))
    if not matches:
        return []
    out: list[str] = []
    for match in matches:
        if _is_protected_number(answer, match.start(), match.end()):
            continue
        n = int(match.group(0))
        candidates = {n - 1, n + 1, n + 2, n * 2}
        if n > 2:
            candidates.add(n - 2)
        if n % 2 == 0 and n > 2:
            candidates.add(n // 2)
        if n in {8, 16, 24, 32, 64, 128, 256, 512, 1024}:
            candidates.update({v for v in NEARBY if v != n})
        candidates.discard(n)
        candidates = {v for v in candidates if v > 0}
        for v in sorted(candidates):
            out.append(answer[: match.start()] + str(v) + answer[match.end() :])
            if len(out) >= 8:
                return out
    return out


def verb_variants(answer: str) -> list[str]:
    out = []
    for src, dst in VERBS:
        pattern = rf"\b{re.escape(src)}\b"
        if re.search(pattern, answer):
            out.append(re.sub(pattern, dst, answer, count=1))
    return out


def swap_variants(answer: str) -> list[str]:
    out = []
    for src, dst in SWAPS:
        if src in answer and dst not in answer:
            out.append(answer.replace(src, dst, 1))
    return out


WORD_SWAPS = [
    ("physischen", "virtuellen"),
    ("virtuellen", "physischen"),
    ("logischen", "physischen"),
    ("Bestandteile", "Schnittstellen"),
    ("Computersystems", "Netzwerks"),
    ("Ereignisse", "Kennwörter"),
    ("Protokollen", "Tabellen"),
]


def word_swap_variants(answer: str) -> list[str]:
    out = []
    for src, dst in WORD_SWAPS:
        if src in answer and dst not in answer:
            out.append(answer.replace(src, dst, 1))
    return out


_VERB_INSERT = (
    r"ist|sind|wird|werden|hat|haben|kann|können|bezeichnet|besteht|verwaltet|"
    r"überwacht|zeichnet|vergibt|trennt|ermöglicht|prüft|sendet|empfängt|"
    r"definiert|beschreibt|regelt|enthält|dient|sorgt|stellt|grenzt|"
    r"führt|verarbeitet|erzeugt|sichert|steuert"
)


def structural_mutations(answer: str) -> list[str]:
    out: list[str] = []
    match = re.search(rf"\b({_VERB_INSERT})\b", answer)
    if match and " nicht" not in answer[match.end() : match.end() + 8]:
        out.append(answer[: match.end()] + " nicht" + answer[match.end() :])
    swapped_all = re.sub(r"\balle\b", "keine", answer, count=1, flags=re.I)
    if swapped_all != answer:
        out.append(swapped_all)
    swapped_only = re.sub(r"\bnur\b", "beliebig viele", answer, count=1, flags=re.I)
    if swapped_only != answer:
        out.append(swapped_only)
    words = answer.split()
    if len(words) == 2:
        out.append(f"kein {answer}")
        out.append(f"{words[0]} ohne {words[1]}")
    return out


def negate_variant(answer: str) -> str | None:
    if " nicht " in f" {answer} ":
        return None
    for token in (" ist ", " sind ", " wird ", " werden ", " hat ", " haben ", " kann ", " können "):
        if token in f" {answer} ":
            return answer.replace(token.strip(), token.strip() + " nicht", 1)
    return None


def unique_add(bucket: list[str], seen: set[str], text: str, correct: str) -> None:
    value = (text or "").strip()
    if not value or len(value) > 400:
        return
    key = norm(value)
    if not key or key in seen or key == norm(correct):
        return
    if is_junk(value):
        return
    seen.add(key)
    bucket.append(value)


def generate(question: str, answer: str) -> list[str]:
    seen = {norm(answer)}
    out: list[str] = []
    for candidate in numeric_variants(answer):
        unique_add(out, seen, candidate, answer)
    for candidate in swap_variants(answer):
        unique_add(out, seen, candidate, answer)
    for candidate in verb_variants(answer):
        unique_add(out, seen, candidate, answer)
    for candidate in word_swap_variants(answer):
        unique_add(out, seen, candidate, answer)
    for candidate in structural_mutations(answer):
        unique_add(out, seen, candidate, answer)
    negated = negate_variant(answer)
    if negated:
        unique_add(out, seen, negated, answer)

    quantity = bool(re.search(r"wie viele|wieviel|aus wie vielen", question, re.I)) or bool(
        re.search(r"\d", answer)
    )
    if quantity:
        numbered = [w for w in out if re.search(r"\d", w)]
        if len(numbered) >= 3:
            out = numbered

    if len(out) < 3:
        unique_add(out, seen, answer.replace(" und ", " oder ", 1), answer)
        unique_add(out, seen, answer.replace(" oder ", " und ", 1), answer)
        unique_add(out, seen, re.sub(r"\balle\b", "keine", answer, count=1, flags=re.I), answer)
        unique_add(out, seen, re.sub(r"\bnur\b", "beliebig viele", answer, count=1, flags=re.I), answer)
        unique_add(out, seen, re.sub(r"\bimmer\b", "niemals", answer, count=1, flags=re.I), answer)
        unique_add(out, seen, re.sub(r"\bniemals\b", "immer", answer, count=1, flags=re.I), answer)
        unique_add(out, seen, re.sub(r"\bmuss\b", "darf nicht", answer, count=1, flags=re.I), answer)
        unique_add(out, seen, answer.replace(" ist ", " ist ausschließlich ", 1), answer)

    if quantity:
        numbered = [w for w in out if re.search(r"\d", w)]
        if len(numbered) >= 3:
            out = numbered

    if len(out) < 3:
        unique_add(out, seen, re.sub(r",", " nicht,", answer, count=1), answer)
        unique_add(out, seen, answer.rstrip(".") + " nicht.", answer)
        unique_add(out, seen, answer.replace(" die ", " keine ", 1), answer)
        unique_add(out, seen, answer.replace(" der ", " keiner ", 1), answer)
        unique_add(out, seen, answer.replace(" das ", " kein ", 1), answer)
        unique_add(out, seen, re.sub(r"^(Die|Der|Das)\b", "Keine", answer, count=1), answer)
        unique_add(out, seen, re.sub(r"^(Ein|Eine)\b", "Kein", answer, count=1), answer)

    if len(out) < 3:
        words = answer.split()
        for i, word in enumerate(words):
            if i == 0 or len(word) < 4:
                continue
            cloned = list(words)
            cloned[i] = f"nicht-{word}"
            unique_add(out, seen, " ".join(cloned), answer)
            if len(out) >= 3:
                break

    if len(out) < 3:
        raise RuntimeError(f"Keine 3 Distraktoren für: {question}")
    return out[:3]


def has_relevance(question: str, answer: str, wrong: str) -> bool:
    if is_junk(wrong):
        return False
    subject = extract_subject(question, answer)
    if subject and norm(subject).split()[0] in norm(wrong):
        return True
    if re.search(r"\d", answer) and re.search(r"\d", wrong):
        return True
    a_tokens = set(norm(answer).split())
    w_tokens = set(norm(wrong).split())
    return len(a_tokens & w_tokens) >= 2


_DEF_START = re.compile(
    r"^(?:Ein |Eine |Der |Die |Das )?"
    r"([A-Za-zÄÖÜäöü0-9][A-Za-zÄÖÜäöü0-9./+-]{1,40})"
    r"\s+(ist|sind|bedeutet|bezeichnet|umfasst|beschreibt|regelt|enthält)\b",
    re.I,
)


def defines_other_term(text: str, question: str, answer: str) -> bool:
    match = _DEF_START.match(text.strip())
    if not match:
        return False
    other = norm(match.group(1))
    hay = f"{norm(question)} {norm(answer)}"
    return other and other not in hay


def keep_existing(question: str, answer: str, wrongs: list[str]) -> bool:
    filled = [w.strip() for w in wrongs]
    if len(filled) != 3 or any(not w for w in filled):
        return False
    # Nur kurze, bereits passende Zahlenalternativen behalten.
    if not all(re.search(r"\d", w) and len(w) <= 48 for w in filled):
        return False
    keys = {norm(answer)}
    for w in filled:
        if is_junk(w) or not has_relevance(question, answer, w):
            return False
        if defines_other_term(w, question, answer):
            return False
        if re.search(r"(belöscht|geverwirft|-Protokoll\.)", w):
            return False
        key = norm(w)
        if key in keys:
            return False
        keys.add(key)
    return True


def rewrite_file(path: pathlib.Path) -> tuple[int, int]:
    with path.open("r", encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh, delimiter=";"))
    if not rows:
        return 0, 0
    header, data = rows[0], rows[1:]
    kept = 0
    replaced = 0
    out_rows = [header[:5] or ["Frage", "Antwort", "FalscheAntwort1", "FalscheAntwort2", "FalscheAntwort3"]]
    if len(out_rows[0]) < 5:
        out_rows[0] = ["Frage", "Antwort", "FalscheAntwort1", "FalscheAntwort2", "FalscheAntwort3"]
    for row in data:
        if len(row) < 2 or not row[0].strip() or not row[1].strip():
            continue
        question, answer = row[0].strip(), row[1].strip()
        existing = [(row[i].strip() if i < len(row) else "") for i in range(2, 5)]
        if keep_existing(question, answer, existing):
            wrongs = existing
            kept += 1
        else:
            wrongs = generate(question, answer)
            replaced += 1
        out_rows.append([question, answer, *wrongs])

    with path.open("w", encoding="utf-8-sig", newline="") as fh:
        writer = csv.writer(fh, delimiter=";", lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
        writer.writerows(out_rows)
    return kept, replaced


def main() -> None:
    total_kept = total_replaced = 0
    files = sorted(DECKS.glob("*.csv"))
    for path in files:
        kept, replaced = rewrite_file(path)
        total_kept += kept
        total_replaced += replaced
        print(f"{path.name}: behalten {kept}, ersetzt {replaced}")
    print(f"Summe behalten {total_kept}, ersetzt {total_replaced}, Dateien {len(files)}")


if __name__ == "__main__":
    main()
