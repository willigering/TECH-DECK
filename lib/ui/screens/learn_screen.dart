import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../data/models/flashcard.dart';
import '../../logic/study_order.dart';
import '../../state/deck_controller.dart';
import '../widgets/flip_card.dart';
import '../widgets/gold_button.dart';
import '../widgets/pcb_background.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, required this.topicId});

  final String topicId;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  List<Flashcard> _cards = const [];
  int _index = 0;
  bool _flipped = false;
  bool _loading = true;
  String? _error;

  Flashcard? get _current =>
      _cards.isEmpty ? null : _cards[_index.clamp(0, _cards.length - 1)];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards =
          await context.read<DeckController>().cardsFor(widget.topicId);
      if (!mounted) return;
      setState(() {
        _cards = shuffledCopy(cards, Random());
        _loading = false;
        _index = 0;
        _flipped = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _flip() async {
    final card = _current;
    if (card == null) return;
    final becomingBack = !_flipped;
    setState(() => _flipped = !_flipped);
    if (becomingBack) {
      await context.read<DeckController>().markSeen(card.id);
      setState(() {
        _cards[_index] = card.copyWith(
          timesSeen: card.timesSeen + 1,
          lastSeen: DateTime.now(),
        );
      });
    }
  }

  void _go(int delta) {
    if (_cards.isEmpty) return;
    final next = (_index + delta).clamp(0, _cards.length - 1);
    if (next == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = next;
      _flipped = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final card = _current;
    if (card == null) return;
    await context.read<DeckController>().toggleFavorite(card.id);
    setState(() {
      _cards[_index] = card.copyWith(isFavorite: !card.isFavorite);
    });
  }

  void _reshuffle() {
    if (_cards.length < 2) return;
    HapticFeedback.selectionClick();
    setState(() {
      _cards = shuffledCopy(_cards, Random());
      _index = 0;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _current;

    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Lernen'),
          actions: [
            if (_cards.length > 1)
              IconButton(
                tooltip: 'Karten mischen',
                icon: const Icon(Icons.shuffle_rounded),
                onPressed: _reshuffle,
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: TdColors.gold),
                  )
                : _error != null
                    ? Center(child: Text(_error!))
                    : card == null
                        ? const Center(
                            child: Text('Keine Karten in diesem Thema.'),
                          )
                        : Column(
                            children: [
                              Text(
                                '${_index + 1} / ${_cards.length}',
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 13,
                                  letterSpacing: 2,
                                  color: TdColors.gold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GoldProgressBar(
                                value: (_index + 1) / _cards.length,
                              ),
                              const SizedBox(height: 22),
                              Expanded(
                                child: FlipStudyCard(
                                  key: ValueKey(card.id),
                                  question: card.question,
                                  answer: card.answer,
                                  flipped: _flipped,
                                  onFlip: _flip,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (!_flipped)
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.rotate_right,
                                      size: 16,
                                      color: TdColors.textDim,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tippe zum Umdrehen',
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 15,
                                        color: TdColors.textDim,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                GoldButton(
                                  label: 'NÄCHSTE KARTE',
                                  enabled: _index < _cards.length - 1,
                                  onTap: _index < _cards.length - 1
                                      ? () => _go(1)
                                      : null,
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _RoundAction(
                                    icon: Icons.arrow_back_rounded,
                                    label: 'ZURÜCK',
                                    enabled: _index > 0,
                                    onTap: () => _go(-1),
                                  ),
                                  _RoundAction(
                                    icon: card.isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    label: 'MARKIEREN',
                                    onTap: _toggleFavorite,
                                  ),
                                  _RoundAction(
                                    icon: Icons.arrow_forward_rounded,
                                    label: 'WEITER',
                                    enabled: _index < _cards.length - 1,
                                    onTap: () => _go(1),
                                  ),
                                ],
                              ),
                            ],
                          ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: TdColors.gold),
                  boxShadow: [
                    BoxShadow(
                      color: TdColors.gold.withValues(alpha: 0.18),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(icon, color: TdColors.gold, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  letterSpacing: 1,
                  color: TdColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
