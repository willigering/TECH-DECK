# Play-Store-Vorbereitung 1.7.14+25

Auf ausdrücklichen Nutzerwunsch wird TECH//DECK künftig über Google Play verteilt. Der zuvor vorhandene GitHub-Updater wird vollständig aus dem App-Code entfernt, nicht nur versteckt.

## Änderungen

- Entfernt: Dart-Updater, Update-Provider, Startprüfung und Dialogsteuerung, Update-Einstellungen, nativer MethodChannel/PackageInstaller, Update-Metadatengenerator und alte Updater-Tests/Testplan.
- Hauptmanifest: keine `INTERNET`, `ACCESS_NETWORK_STATE` oder `REQUEST_INSTALL_PACKAGES` mehr. Cleartext-Verbindungen sind deaktiviert; die alte Netzwerk-Ausnahmekonfiguration ist entfernt. Debug-/Profile-Manifeste dürfen weiterhin Flutter-Entwicklungswerkzeuge unterstützen.
- Signierkonfiguration in `android/app/build.gradle.kts`, Paketkennung `com.willigering.tech_deck`, SQLite-Schema und Inhaltsrevision bleiben unverändert. Keine Schlüssel erzeugt, ausgetauscht oder eingebettet. Alte `update_*`-Preferences bleiben ungenutzt; bestehende App-Daten werden nicht gelöscht.
- Version konsistent auf 1.7.14+25 angehoben. Vor einer späteren Veröffentlichung muss die dann aktuelle höchste Buildnummer erneut geprüft werden.
- Manuell startbarer Workflow `.github/workflows/release-apk.yml` (historischer Dateiname) baut jetzt ein signiertes AAB. Signaturprüfung über `jarsigner` und Zertifikat-Fingerprint aus `keytool` gegen die unveränderte Repository-Variable. Keystore wird temporär mit restriktiven Dateirechten erzeugt und per `trap` wieder entfernt. Kein Upload in die Play Console und kein GitHub-Release. Vorlagenkopie unter `tool/github-workflows/` identisch.
- Datenschutzerklärung nennt Willi Gering (Gering Digital), info@geringdigital.de. Sie deckt die neue Offline-/Play-Ausgabe ab, einschließlich lokaler Karten/Preferences, Dateiauswahl, Systembackups, Support-E-Mails, Rechte/Löschung und GitHub-Pages-Hosting. Keine pauschale Aussage über vollständige Anonymität eines Webseitenbesuchs: GitHub erhält dort Verbindungsdaten. Ältere GitHub-Ausgaben werden nicht fälschlich als updaterfrei beschrieben.
- Datenschutztext ist in den Einstellungen offline lesbar; dieselbe Fassung wird als HTML ohne externe Assets/Skripte bereitgestellt.

## Validierung

- `flutter analyze --no-pub`: keine Befunde.
- `flutter test --no-pub --reporter expanded`: 70 Tests erfolgreich. Die Tests des entfernten Updaters sind entfallen. Neu geprüft: Policy-Asset/Kontakt, lesbarer Offline-Datenschutzbildschirm und Ausschluss von Installer-/Updater-/Netzwerkcode im Play-Quellstand.
- Vorhandene Tests für Datenhaltung, Kartenimport/-suche, Markierungen, Favoriten, Navigation, Darstellung und Halloween bleiben erfolgreich.
- YAML geparst, alle Workflow-Shellblöcke mit `bash -n` geprüft; Workflow und Vorlage bytegleich. `git diff --check` sauber.
- HTML geprüft: Titel/Kontakt vorhanden, zehn Abschnitte, keine externen Skripte/Bilder/Iframes.

## Noch offen

1. GitHub Pages ist inzwischen erreichbar: https://willigering.github.io/TECH-DECK/privacy.html. Am 30.10.2026 mit HTTP 200 abgerufen; Kontaktadresse, Versionsbezug 1.7.14 und Erklärung zum entfernten Updater im ausgelieferten HTML verifiziert. Der `gh-pages`-Zweig enthält ausschließlich die Webseite und `.nojekyll`.
2. Diesen PR nach Prüfung freigeben/mergen. Kein Merge oder Release wurde im Rahmen der Vorbereitung durchgeführt.
3. Signiertes AAB in der sicheren Build-Umgebung mit den bestehenden Secrets bauen. Hier ist kein lokaler privater Keystore verfügbar; der Android-Release-Build und die tatsächliche Artefakt-Signatur sind nicht ausgeführt/geprüft. Keine Aussage über einen erfolgreichen Android-Installationstest.
4. Bei erstmaligem Play App Signing vor dem ersten Upload die Schlüsselstrategie festlegen: Derselbe Upload-Schlüssel garantiert nicht dasselbe App-Signaturzertifikat der von Google ausgelieferten APK. Für eine nahtlose Übernahme bestehender GitHub-Installationen muss das bestehende App-Signaturzertifikat berücksichtigt werden. Nicht versehentlich einen unabhängigen App-Signierschlüssel erzeugen lassen.
5. Fertiges AAB einschließlich zusammengeführtem Release-Manifest/SDKs kontrollieren, intern auf einem Android-Gerät testen und die Datensicherheitsangaben in Play Console mit genau diesem Artefakt abgleichen. Das Erstellen dieser Erklärung ersetzt keine Prüfung künftiger Funktions-/SDK-Änderungen.
