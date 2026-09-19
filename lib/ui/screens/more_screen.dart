import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../core/colors.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/topic_tile.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Future<void> _import() async {
    final summary = await context.read<DeckController>().importCsv();
    if (!mounted || summary == null) return;
    _toast(
      '${summary.filesOk} Datei(en) · ${summary.cardsImported} Karten neu · '
      '${summary.duplicates} Duplikate',
    );
  }

  Future<void> _resetStats() async {
    final ok = await _confirm(
      'Statistiken zurücksetzen?',
      'Gelernte Karten und Quiz-Auswertungen werden gelöscht. '
      'Importierte Themen bleiben erhalten.',
    );
    if (ok != true || !mounted) return;
    await context.read<DeckController>().resetStats();
    _toast('Statistiken zurückgesetzt.');
  }

  Future<void> _deleteTopic(String id, String name) async {
    final ok = await _confirm(
      'Thema löschen?',
      '"$name" und alle zugehörigen Karten werden entfernt.',
    );
    if (ok != true || !mounted) return;
    await context.read<DeckController>().deleteTopic(id);
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TdColors.bgPanel,
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Orbitron', color: TdColors.gold),
        ),
        content: Text(body, style: const TextStyle(color: TdColors.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK', style: TextStyle(color: TdColors.gold)),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const BrandHeader(compact: true),
          const SizedBox(height: 22),
          const SectionLabel('APP'),
          const SizedBox(height: 14),
          GoldPanel(
            child: Column(
              children: [
                const TdLogo(size: 96),
                const SizedBox(height: 12),
                const Text(
                  AppInfo.name,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    color: TdColors.goldBright,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppInfo.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 15,
                    color: TdColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                _meta('ENTWICKLER', AppInfo.developer),
                const SizedBox(height: 6),
                _meta('VERSION', '${AppInfo.version} (${AppInfo.buildNumber})'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GoldButton(
            label: 'CSV IMPORTIEREN',
            icon: Icons.file_upload_outlined,
            onTap: _import,
          ),
          const SizedBox(height: 10),
          GoldButton(
            label: 'STATISTIK ZURÜCKSETZEN',
            filled: false,
            onTap: _resetStats,
          ),
          const SizedBox(height: 28),
          const SectionLabel('THEMEN VERWALTEN'),
          const SizedBox(height: 14),
          if (deck.topics.isEmpty)
            const GoldPanel(
              child: Text(
                'Keine Themen vorhanden.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final t in deck.topics) ...[
              TopicTile(
                topic: t,
                onTap: () {},
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: TdColors.danger),
                  onPressed: () => _deleteTopic(t.id, t.name),
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          const Text(
            'Offline. Alle Karten und Statistiken bleiben lokal auf diesem Gerät.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 14,
              color: TdColors.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String k, String v) {
    return Row(
      children: [
        Text(
          k,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            letterSpacing: 1.6,
            color: TdColors.textDim,
          ),
        ),
        const Spacer(),
        Text(
          v,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: TdColors.text,
          ),
        ),
      ],
    );
  }
}
