import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/colors.dart';
import '../../data/models/quiz.dart';
import '../../logic/quiz_generator.dart';
import '../../state/deck_controller.dart';
import '../widgets/gold_button.dart';
import '../widgets/pcb_background.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({
    super.key,
    required this.topicId,
    required this.questionCount,
  });

  final String topicId;
  final int questionCount;

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  List<QuizQuestion> _questions = const [];
  final List<QuizAnswerRecord> _records = [];
  int _index = 0;
  int? _selected;
  bool _loading = true;
  bool _started = false;
  String? _error;

  QuizQuestion? get _current =>
      _questions.isEmpty ? null : _questions[_index];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    try {
      final cards =
          await context.read<DeckController>().cardsFor(widget.topicId);
      final questions =
          QuizGenerator().generate(cards, widget.questionCount);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _select(int i) {
    if (_selected != null) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = i);
  }

  void _skip() {
    final q = _current;
    if (q == null) return;
    _records.add(
      QuizAnswerRecord(
        question: q,
        selectedIndex: null,
        verdict: QuizVerdict.skipped,
      ),
    );
    _advance();
  }

  void _next() {
    final q = _current;
    if (q == null || _selected == null) return;
    final verdict = q.choices[_selected!].isCorrect
        ? QuizVerdict.correct
        : QuizVerdict.wrong;
    _records.add(
      QuizAnswerRecord(
        question: q,
        selectedIndex: _selected,
        verdict: verdict,
      ),
    );
    _advance();
  }

  void _advance() {
    if (_index + 1 >= _questions.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  Future<void> _finish() async {
    final correct =
        _records.where((r) => r.verdict == QuizVerdict.correct).length;
    final wrong =
        _records.where((r) => r.verdict == QuizVerdict.wrong).length;
    final skipped =
        _records.where((r) => r.verdict == QuizVerdict.skipped).length;
    final session = QuizSession(
      id: const Uuid().v4(),
      topicId: widget.topicId,
      questionCount: _records.length,
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      completedAt: DateTime.now(),
      records: List.of(_records),
    );
    await context.read<DeckController>().saveQuiz(session);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _current;
    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('QUIZ'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: TdColors.gold),
                  )
                : _error != null
                    ? Center(child: Text(_error!))
                    : q == null
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Für dieses Thema können keine vollständigen Quizfragen erzeugt werden.\n\nJede Karte braucht genau eine richtige Antwort und drei passende falsche Antworten.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 18,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Text(
                                '${_index + 1} / ${_questions.length}',
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 13,
                                  letterSpacing: 2,
                                  color: TdColors.gold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GoldProgressBar(
                                value: (_index + 1) / _questions.length,
                              ),
                              const SizedBox(height: 20),
                              GoldPanel(
                                child: Text(
                                  q.prompt,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 22,
                                    color: TdColors.text,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: q.options.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) {
                                    return _OptionTile(
                                      letter: String.fromCharCode(65 + i),
                                      text: q.choices[i].text,
                                      selected: _selected == i,
                                      reveal: _selected != null,
                                      correct: q.choices[i].isCorrect,
                                      onTap: () => _select(i),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: GoldButton(
                                      label: 'ÜBERSPRINGEN',
                                      filled: false,
                                      onTap: _selected == null ? _skip : null,
                                      enabled: _selected == null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GoldButton(
                                      label: 'WEITER',
                                      onTap: _selected != null ? _next : null,
                                      enabled: _selected != null,
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.reveal,
    required this.correct,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final bool reveal;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color border = TdColors.gold.withValues(alpha: 0.7);
    Color bg = Colors.black.withValues(alpha: 0.45);
    if (reveal && correct) {
      border = TdColors.goldBright;
      bg = TdColors.goldDeep;
    } else if (reveal && selected && !correct) {
      border = TdColors.danger;
      bg = TdColors.danger.withValues(alpha: 0.18);
    } else if (selected) {
      border = TdColors.gold;
      bg = TdColors.goldDeep.withValues(alpha: 0.8);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: reveal ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                letter,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                  color: TdColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: TdColors.text,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
