import 'package:flutter/material.dart';

import '../services/user_repo.dart';
import '../theme.dart';

class PracticeQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;
  const PracticeQuestion(this.question, this.options, this.answer, this.explanation);
}

// Starter practice questions written for this app. These are not official PYQs.
const _questions = <PracticeQuestion>[
  PracticeQuestion(
    '25 का 20% कितना होगा?',
    ['2', '5', '10', '20'],
    1,
    '20% = 20/100। इसलिए 25 × 20/100 = 5।',
  ),
  PracticeQuestion(
    'पानी का रासायनिक सूत्र क्या है?',
    ['CO₂', 'O₂', 'H₂O', 'NaCl'],
    2,
    'पानी के एक अणु में दो हाइड्रोजन और एक ऑक्सीजन परमाणु होते हैं।',
  ),
  PracticeQuestion(
    'भारत का संविधान कब लागू हुआ?',
    ['15 अगस्त 1947', '26 जनवरी 1950', '2 अक्टूबर 1950', '26 नवंबर 1949'],
    1,
    'भारत का संविधान 26 जनवरी 1950 को लागू हुआ।',
  ),
  PracticeQuestion(
    'विद्युत धारा की SI इकाई क्या है?',
    ['वोल्ट', 'ओम', 'एम्पियर', 'वाट'],
    2,
    'विद्युत धारा की SI इकाई एम्पियर (A) है।',
  ),
  PracticeQuestion(
    'श्रृंखला परिपथ में सभी अवयवों में क्या समान रहता है?',
    ['वोल्टेज', 'धारा', 'प्रतिरोध', 'शक्ति'],
    1,
    'श्रृंखला परिपथ में प्रत्येक अवयव से समान धारा गुजरती है।',
  ),
];

class PracticeQuizScreen extends StatefulWidget {
  final UserRepo repo;
  const PracticeQuizScreen({super.key, required this.repo});

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  int _index = 0;
  int? _selected;
  int _score = 0;
  bool _answered = false;
  bool _saving = false;
  bool _saved = false;
  String? _saveError;
  final List<int> _answers = [];

  PracticeQuestion get _current => _questions[_index];
  bool get _finished => _index >= _questions.length;

  void _checkAnswer() {
    if (_selected == null || _answered) return;
    setState(() {
      _answered = true;
      _answers.add(_selected!);
      if (_selected == _current.answer) _score++;
    });
  }

  void _next() {
    if (!_answered) return;
    if (_index == _questions.length - 1) {
      setState(() => _index = _questions.length);
      _saveAttempt();
    } else {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    }
  }

  Future<void> _saveAttempt() async {
    if (_saving || _saved) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.repo.saveQuizAttempt(
        quizId: 'starter_basics_01',
        score: _score,
        total: _questions.length,
        answers: List<int>.from(_answers),
      );
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _score = 0;
      _answered = false;
      _saving = false;
      _saved = false;
      _saveError = null;
      _answers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _resultPage();
    final q = _current;
    return Scaffold(
      appBar: AppBar(title: const Text('प्रैक्टिस टेस्ट')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'शुरुआती अभ्यास सेट • 5 प्रश्न\nये अभ्यास के लिए बनाए गए नमूना प्रश्न हैं, आधिकारिक PYQ नहीं।',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('प्रश्न ${_index + 1} / ${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('सही: $_score'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (_index + 1) / _questions.length),
            const SizedBox(height: 24),
            Text(q.question,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: _answered && i == q.answer
                      ? Colors.green.shade50
                      : (_answered && i == _selected
                          ? Colors.red.shade50
                          : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _answered ? null : () => setState(() => _selected = i),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selected == i ? kTeal : const Color(0xFFD5E0DE),
                          width: _selected == i ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _answered && i == q.answer
                                ? Icons.check_circle
                                : (_answered && i == _selected
                                    ? Icons.cancel
                                    : (_selected == i
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off)),
                            color: _answered && i == q.answer
                                ? Colors.green
                                : (_answered && i == _selected
                                    ? Colors.red
                                    : kTeal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(q.options[i], style: const TextStyle(fontSize: 17))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_answered)
              Card(
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected == q.answer ? 'सही जवाब!' : 'सही उत्तर: ${q.options[q.answer]}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 6),
                      Text(q.explanation),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _answered ? _next : (_selected == null ? null : _checkAnswer),
              child: Text(_answered
                  ? (_index == _questions.length - 1 ? 'परिणाम देखें' : 'अगला प्रश्न')
                  : 'उत्तर जाँचें'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultPage() {
    final percent = (_score * 100 / _questions.length).round();
    return Scaffold(
      appBar: AppBar(title: const Text('टेस्ट का परिणाम')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.emoji_events_outlined, size: 72, color: kTeal),
            const SizedBox(height: 16),
            const Text('आपका परिणाम', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('$_score / ${_questions.length} सही • $percent%',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 18),
            if (_saving) const Center(child: CircularProgressIndicator()),
            if (_saved)
              const Text('आपका परिणाम आपके खाते में सुरक्षित हो गया।',
                  textAlign: TextAlign.center),
            if (_saveError != null) ...[
              Text('परिणाम सेव नहीं हुआ: $_saveError',
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _saveAttempt, child: const Text('दोबारा सेव करें')),
            ],
            if (!_saving && !_saved && _saveError == null)
              OutlinedButton(onPressed: _saveAttempt, child: const Text('परिणाम सेव करें')),
            const SizedBox(height: 18),
            FilledButton(onPressed: _restart, child: const Text('फिर से टेस्ट दें')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('डैशबोर्ड पर जाएँ')),
          ],
        ),
      ),
    );
  }
}
