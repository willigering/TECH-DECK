#!/usr/bin/env python3
"""Generates techdeck-update.json + SHA256SUMS for a TECH//DECK release.

Usage: tool/update_metadata.py <out_dir> <apk>...
Reads package name, versions, minSdk via aapt2 and signer via apksigner (both
from Android build-tools on PATH). Fails loudly on any inconsistency.
"""
import hashlib, json, os, re, subprocess, sys

PACKAGE = "com.willigering.tech_deck"


def run(*cmd):
    return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout


def main():
    out_dir, apks = sys.argv[1], sys.argv[2:]
    if not apks:
        sys.exit("no APKs given")
    entries, info, certs = [], None, None
    for apk in apks:
        badging = run("aapt2", "dump", "badging", apk)
        m = re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", badging)
        sdk = re.search(r"minSdkVersion:'(\d+)'", badging)
        abis = re.search(r"native-code: (.*)", badging)
        if not m or not sdk:
            sys.exit(f"cannot read manifest of {apk}")
        cur = (m.group(1), int(m.group(2)), m.group(3), int(sdk.group(1)))
        if cur[0] != PACKAGE:
            sys.exit(f"wrong package id {cur[0]}")
        if info and info != cur:
            sys.exit("APKs disagree on version")
        info = cur
        signer = run("apksigner", "verify", "--print-certs", apk)
        c = sorted(set(re.findall(r"certificate SHA-256 digest: ([0-9a-f]{64})", signer)))
        if not c or (certs and certs != c):
            sys.exit("missing or inconsistent signer")
        certs = c
        name = os.path.basename(apk)
        found = re.findall(r"'([^']+)'", abis.group(1)) if abis else []
        # A split APK carries exactly one ABI; universal APKs list all of them.
        entries.append({
            "name": name,
            "size": os.path.getsize(apk),
            "sha256": hashlib.sha256(open(apk, "rb").read()).hexdigest(),
            "abis": found if len(found) == 1 else [],
        })
    meta = {
        "schema": 1,
        "packageName": info[0],
        "versionCode": info[1],
        "versionName": info[2],
        "minSdk": info[3],
        "signingCertSha256": certs,
        "apks": entries,
    }
    with open(os.path.join(out_dir, "techdeck-update.json"), "w") as f:
        json.dump(meta, f, indent=2)
    with open(os.path.join(out_dir, "SHA256SUMS"), "w") as f:
        for e in entries:
            f.write(f"{e['sha256']}  {e['name']}\n")
    print(json.dumps(meta, indent=2))


if __name__ == "__main__":
    main()
