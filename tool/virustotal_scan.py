#!/usr/bin/env python3
"""VirusTotal-Scan fuer Release-Dateien (nur Standardbibliothek).

Nutzung:
  VIRUSTOTAL_API_KEY=... python3 tool/virustotal_scan.py DATEI [--repo OWNER/REPO --tag TAG]
Mit --tag wird ein Abschnitt "Virenpruefung" an die Release Notes angehaengt (via gh).
Exit-Code 0 = ok, 2 = VT-Fehler (in CI nicht fatal behandeln).
"""
import argparse, datetime, hashlib, json, os, subprocess, sys, time, uuid, urllib.request, urllib.error

API = "https://www.virustotal.com/api/v3"
MIN_INTERVAL = 15.5  # Free-API: 4 Anfragen/Minute
_last = [0.0]

def req(url, key, data=None, headers=None, method=None):
    wait = MIN_INTERVAL - (time.time() - _last[0])
    if wait > 0: time.sleep(wait)
    _last[0] = time.time()
    h = {"x-apikey": key, "accept": "application/json"}; h.update(headers or {})
    r = urllib.request.Request(url, data=data, headers=h, method=method)
    try:
        with urllib.request.urlopen(r, timeout=600) as resp:
            return resp.status, json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as e:
        body = e.read()
        try: return e.code, json.loads(body)
        except Exception: return e.code, {"raw": body[:300].decode(errors="replace")}

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""): h.update(b)
    return h.hexdigest()

def upload(path, key):
    size = os.path.getsize(path)
    url = API + "/files"
    if size > 32 * 1024 * 1024:
        st, j = req(API + "/files/upload_url", key)
        if st != 200: raise RuntimeError(f"upload_url fehlgeschlagen: {st} {j}")
        url = j["data"]
    b = uuid.uuid4().hex
    with open(path, "rb") as f: content = f.read()
    body = (f"--{b}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{os.path.basename(path)}\"\r\n"
            "Content-Type: application/octet-stream\r\n\r\n").encode() + content + f"\r\n--{b}--\r\n".encode()
    st, j = req(url, key, data=body, headers={"Content-Type": f"multipart/form-data; boundary={b}"}, method="POST")
    if st != 200: raise RuntimeError(f"Upload fehlgeschlagen: {st} {j}")
    return j["data"]["id"]

def scan(path, key, timeout=1800):
    analysis = upload(path, key)
    start = time.time()
    while time.time() - start < timeout:
        st, j = req(f"{API}/analyses/{analysis}", key)
        if st == 200 and j["data"]["attributes"]["status"] == "completed":
            return j["data"]["attributes"]["stats"]
        if st == 404 and time.time() - start < 300: pass  # Analyse noch nicht sichtbar
        elif st not in (200, 429): raise RuntimeError(f"Analyse-Abfrage fehlgeschlagen: {st} {j}")
        time.sleep(30)
    raise RuntimeError("Zeitueberschreitung beim Warten auf die Analyse")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file"); ap.add_argument("--repo"); ap.add_argument("--tag")
    a = ap.parse_args()
    key = os.environ.get("VIRUSTOTAL_API_KEY")
    if not key: print("VT-FEHLER: VIRUSTOTAL_API_KEY fehlt", file=sys.stderr); return 2
    digest = sha256(a.file)
    link = f"https://www.virustotal.com/gui/file/{digest}"
    try:
        s = scan(a.file, key)
    except Exception as e:
        print(f"VT-FEHLER: {e}", file=sys.stderr); return 2
    bad = s.get("malicious", 0) + s.get("suspicious", 0)
    total = s.get("malicious", 0) + s.get("suspicious", 0) + s.get("undetected", 0) + s.get("harmless", 0)
    print(json.dumps(s)); print(f"{total - bad}/{total} Scanner ohne Befund"); print(link)
    if a.tag:
        date = datetime.date.today().strftime("%d.%m.%Y")
        cmd = ["gh", "release", "view", a.tag, "--json", "body", "--jq", ".body"] + (["-R", a.repo] if a.repo else [])
        body = subprocess.run(cmd, check=True, capture_output=True, text=True).stdout.rstrip()
        sec = (f"\n\n## Virenprüfung\n\n`{os.path.basename(a.file)}` auf VirusTotal: "
               f"**{total - bad}/{total} Scanner ohne Befund**"
               + (f" ({bad} Meldungen)" if bad else "") + f" (geprüft am {date})\n\n{link}\n")
        cmd = ["gh", "release", "edit", a.tag, "--notes", body + sec] + (["-R", a.repo] if a.repo else [])
        subprocess.run(cmd, check=True)
        print("Release Notes ergaenzt.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
