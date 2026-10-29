# Manueller Testablauf: Auto-Update mit zwei aufeinanderfolgenden APKs

Ziel: Nachweis, dass eine installierte Version **ohne Deinstallation** über den In-App-Updater aktualisiert wird und alle Daten erhalten bleiben. Muss auf einem echten Android-Gerät (oder Emulator) erfolgen.

## Voraussetzungen
- Release-Schlüssel (Zertifikat SHA-256 `0cea186b…754d`) auf dem Build-PC bzw. in `android/key.properties`.
- Testgerät Android 7.0+ (minSdk 24), `adb` optional.
- Zum Testen ohne echten Release empfiehlt sich ein Fork oder ein temporärer, sofort wieder gelöschter Release – **nicht** im Produktiv-Repo veröffentlichen ohne Freigabe.

## Ablauf
1. **Version A bauen**: Branch-Stand mit Updater, `1.7.12+23`. `flutter build apk --release`. Signatur prüfen: `apksigner verify --print-certs <apk>` → SHA-256 `0cea186b…`.
2. **Ausgangslage**: 1.7.11 deinstallieren (anderer Schlüssel), 1.7.12+23 installieren. Daten anlegen: eine CSV importieren, ein Thema farbig/wichtig markieren, einige Karten lernen, Theme auf „Midnight / Silver“ stellen, Willkommen ausblenden.
3. Daten aus Schritt 2 in 1.7.12 anlegen.
4. **Version B bauen**: `1.7.13+24` (pubspec + AppInfo + Versionshinweise), gleicher Schlüssel, `tool/update_metadata.py` ausführen.
5. **B bereitstellen**: als stabilen (nicht Pre-)Release `v1.7.13` mit APK, `techdeck-update.json`, `SHA256SUMS` im Test-Repo veröffentlichen.
6. **Updateprüfung**: In A *Einstellungen → SOFTWARE UPDATES → JETZT NACH UPDATES SUCHEN*. Erwartung: Dialog „SYSTEM UPDATE AVAILABLE“, Installiert 1.7.12, Verfügbar 1.7.13, Release Notes als Klartext.
7. **SPÄTER ERINNERN** tippen → App bedienbar, kein erneuter Dialog bis zur nächsten Prüfung.
8. **WLAN-Regel**: mobile Daten, WLAN aus → JETZT AKTUALISIEREN → Hinweis „nur über WLAN“. Option deaktivieren → Download startet.
9. **Abbruch**: während des Downloads DOWNLOAD ABBRECHEN → Fehlermeldung, App läuft, `cache/updates` leer.
10. **Unterbrechung**: während des Downloads Flugmodus → saubere Fehlermeldung.
11. **Installation**: JETZT AKTUALISIEREN → ggf. „Unbekannte Apps installieren“ erlauben → Android-Installer „Aktualisieren“ → bestätigen.
12. **Nachkontrolle**: App startet als 1.7.13+24 (*Installierte Version*), alle Daten aus Schritt 2 vorhanden, „Letzte Updateprüfung“ gesetzt.
13. **Keine Doppelangebote**: erneut prüfen → „SYSTEM UP TO DATE – Ausnahmsweise mal nichts kaputt.“
14. **Negativtest Signatur**: B mit anderem Schlüssel signieren und als Release bereitstellen → App verweigert Installation mit Hinweis auf anderen Schlüssel.
15. **Negativtest Downgrade**: Release mit kleinerem `versionCode` → kein Update angeboten.
16. **Offline-Start**: Flugmodus, App starten → normale Funktion, kein Fehlerdialog.
