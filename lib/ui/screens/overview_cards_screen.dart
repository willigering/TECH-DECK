import 'package:flutter/material.dart';

import '../../data/models/overview_card.dart';
import '../widgets/gold_button.dart';

class OverviewCardsScreen extends StatefulWidget {
  const OverviewCardsScreen({super.key});

  @override
  State<OverviewCardsScreen> createState() => _OverviewCardsScreenState();
}

class _OverviewCardsScreenState extends State<OverviewCardsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = overviewCards
        .where((card) => card.matches(_search.text))
        .toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Übersichtskarten')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Karten suchen …',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Suche löschen',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Keine Übersichtskarten gefunden.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: cards.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return GoldPanel(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OverviewCardScreen(card: card),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  card.asset,
                                  width: 64,
                                  height: 96,
                                  fit: BoxFit.contain,
                                  cacheWidth: 192,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(card.description),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewCardScreen extends StatefulWidget {
  const OverviewCardScreen({super.key, required this.card});
  final OverviewCard card;

  @override
  State<OverviewCardScreen> createState() => _OverviewCardScreenState();
}

class _OverviewCardScreenState extends State<OverviewCardScreen> {
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: Text(widget.card.title),
      actions: [
        IconButton(
          tooltip: 'Ansicht zurücksetzen',
          icon: const Icon(Icons.fit_screen),
          onPressed: () => _transform.value = Matrix4.identity(),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    widget.card.asset,
                    fit: BoxFit.contain,
                    semanticLabel:
                        '${widget.card.title}: ${widget.card.description}',
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text('Mit zwei Fingern vergrößern und verschieben.'),
          ),
        ],
      ),
    ),
  );
}
