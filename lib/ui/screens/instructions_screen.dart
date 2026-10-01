import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/brand.dart';
import '../widgets/gold_button.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  static const aiPrompt = '''Erstelle [ANZAHL] Lernkarten zum Thema „[THEMA]“.

Recherchiere die Inhalte sorgfältig anhand seriöser, etablierter und möglichst aktueller Fachquellen. Erfinde keine Fragen, Antworten, Begriffe oder Fakten. Prüfe jede Antwort vor der Ausgabe auf fachliche Richtigkeit.

Regeln:
- Eine eindeutige Frage pro Lernkarte.
- Kurze, präzise und fachlich korrekte Antwort.
- Keine doppelten oder nahezu identischen Fragen.
- Decke die wichtigsten Grundlagen und praxisrelevanten Inhalte des Themas ab.
- Verwende etablierte Fachbegriffe.
- Bei widersprüchlichen oder nicht sicher belegbaren Informationen keine Lernkarte erstellen.

Gib ausschließlich CSV-Inhalt aus, ohne Einleitung, Codeblock oder Begleittext.

CSV:
Frage;Antwort
Was ist ...?;...

Keine Nummerierung, keine erfundenen Inhalte und keinen zusätzlichen Text außerhalb der Lernkarten.''';

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: aiPrompt));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Prompt kopiert')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const SectionLabel('ANLEITUNG'),
          const SizedBox(height: 14),
          GoldPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eigene Lernkarten erstellen',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '1. Wähle eine KI deiner Wahl.\n'
                  '2. Kopiere den Prompt unten.\n'
                  '3. Ersetze [ANZAHL] und [THEMA].\n'
                  '4. Lass die KI die Inhalte recherchieren.\n'
                  '5. Speichere das Ergebnis als .csv.\n'
                  '6. Öffne Einstellungen → Lernkarten importieren.\n'
                  '7. Decks kannst du farblich und als wichtig markieren (lange drücken). Klausurvorbereitung ist vorausgewählt.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    height: 1.45,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('PROMPT FÜR DEINE KI'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: .55),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              aiPrompt,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .65),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('PROMPT KOPIEREN'),
          ),
          const SizedBox(height: 24),
          const SectionLabel('UNTERSTÜTZTE DATEIEN'),
          const SizedBox(height: 10),
          GoldPanel(
            child: Text(
              'CSV: Erste Zeile „Frage;Antwort“, danach eine Karte pro Zeile.\n\n'
              'Der Dateiname wird beim Import als Themenname verwendet.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
