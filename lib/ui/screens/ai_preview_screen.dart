import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../data/ai/distractor_api.dart';
import '../../logic/distractor_validator.dart';
import '../../logic/import_analyzer.dart';
import '../../state/deck_controller.dart';
import '../widgets/gold_button.dart';
import '../widgets/pcb_background.dart';

enum AiPreviewMode { generateMissing, reviewExisting }

class AiPreviewScreen extends StatefulWidget {
  const AiPreviewScreen({
    super.key,
    required this.analyses,
    required this.mode,
  });

  final List<ImportAnalysis> analyses;
  final AiPreviewMode mode;

  @override
  State<AiPreviewScreen> createState() => _AiPreviewScreenState();
}

class _AiPreviewScreenState extends State<AiPreviewScreen> {
  final _api = DistractorApi();
  final _controllers = <int, List<TextEditingController>>{};
  late final List<ImportCardDraft> _targets;
  int _index = 0;
  bool _busy = false;
  String? _error;
  int _requestCount = 0;

  ImportCardDraft get _current => _targets[_index];

  @override
  void initState() {
    super.initState();
    _targets = [
      for (final analysis in widget.analyses)
        for (final card in analysis.cards)
          if (_include(card)) card,
    ];
    if (_targets.isNotEmpty) {
      _ensureControllers(0);
      _loadSuggestion(0);
    }
  }

  bool _include(ImportCardDraft card) {
    if (card.state == ImportCardState.duplicateQuestion) return false;
    if (widget.mode == AiPreviewMode.generateMissing) {
      return card.state == ImportCardState.missingDistractors ||
          card.state == ImportCardState.invalidDistractors;
    }
    return card.state == ImportCardState.quizReady;
  }

  List<TextEditingController> _ensureControllers(int index) {
    return _controllers.putIfAbsent(index, () {
      final draft = _targets[index];
      final seed = draft.aiSuggestion ??
          draft.wrongAnswers.where((e) => e.trim().isNotEmpty).toList();
      return List.generate(
        3,
        (i) => TextEditingController(text: i < seed.length ? seed[i] : ''),
      );
    });
  }

  Future<void> _loadSuggestion(int index) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = _targets[index];
      final values = await _api.generate(
        question: draft.question,
        correctAnswer: draft.answer,
        existingWrongAnswers: draft.wrongAnswers,
      );
      _requestCount++;
      draft.aiSuggestion = values;
      final ctrls = _ensureControllers(index);
      for (var i = 0; i < 3; i++) {
        ctrls[i].text = values[i];
      }
    } on DistractorApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'KI-Anfrage fehlgeschlagen. Du kannst die Felder selbst ausfüllen.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyEditors() {
    final ctrls = _ensureControllers(_index);
    _current.aiSuggestion = ctrls.map((c) => c.text.trim()).toList();
  }

  Future<void> _accept() async {
    _applyEditors();
    final issue = DistractorValidator.issueFor(
      _current.aiSuggestion ?? const [],
      _current.answer,
    );
    if (issue != null) {
      setState(() => _error = issue);
      return;
    }
    _goNext();
  }

  void _reject() {
    _current.aiSuggestion = null;
    _goNext();
  }

  void _goNext() {
    if (_index + 1 >= _targets.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _error = null;
    });
    final draft = _current;
    if (draft.aiSuggestion == null) {
      _loadSuggestion(_index);
    } else {
      _ensureControllers(_index);
    }
  }

  Future<void> _finish() async {
    final summary = await context.read<DeckController>().commitAnalyses(
          widget.analyses,
          learnOnly: false,
        );
    if (!mounted) return;
    Navigator.of(context).pop(summary);
  }

  @override
  void dispose() {
    for (final list in _controllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targets.isEmpty) {
      return const PcbBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Keine Karten für die KI-Prüfung.')),
        ),
      );
    }
    final draft = _current;
    final ctrls = _ensureControllers(_index);
    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('KI-Vorschau')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Text(
                  '${_index + 1} / ${_targets.length}  ·  $_requestCount KI-Anfragen',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    letterSpacing: 1.6,
                    color: TdColors.gold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      GoldPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('FRAGE', style: _label),
                            const SizedBox(height: 6),
                            Text(draft.question, style: _body),
                            const SizedBox(height: 12),
                            const Text('RICHTIGE ANTWORT', style: _label),
                            const SizedBox(height: 6),
                            Text(draft.answer, style: _body),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < 3; i++) ...[
                        Text('FALSCHE ANTWORT ${i + 1}', style: _label),
                        const SizedBox(height: 6),
                        TextField(
                          controller: ctrls[i],
                          maxLines: 3,
                          style: _body,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.45),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: TdColors.goldLine),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: TdColors.gold),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(color: TdColors.gold),
                          ),
                        ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            color: TdColors.danger,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
                GoldButton(
                  label: 'AKZEPTIEREN',
                  onTap: _busy ? null : _accept,
                  enabled: !_busy,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GoldButton(
                        label: 'ABLEHNEN',
                        filled: false,
                        onTap: _busy ? null : _reject,
                        enabled: !_busy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GoldButton(
                        label: 'NEU',
                        filled: false,
                        onTap: _busy ? null : () => _loadSuggestion(_index),
                        enabled: !_busy,
                      ),
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

const _label = TextStyle(
  fontFamily: 'Orbitron',
  fontSize: 11,
  letterSpacing: 1.6,
  color: TdColors.gold,
);
const _body = TextStyle(
  fontFamily: 'Rajdhani',
  fontSize: 17,
  height: 1.3,
  color: TdColors.text,
);
