import 'package:flutter/material.dart';

import '../services/user_repo.dart';
import '../services/ai_teacher_service.dart';
import '../theme.dart';
import 'ai_teacher.dart';

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
  final List<Map<String, dynamic>> _responses = [];
  List<PracticeQuestion> _activeQuestions = List<PracticeQuestion>.from(_questions);
  bool _generating = false;
  bool _isAiQuiz = false;

  PracticeQuestion get _current => _activeQuestions[_index];
  bool get _finished => _index >= _activeQuestions.length;

  Future<void> _generateQuiz() async {
    final topicController = TextEditingController();
    var count = 5;
    final request = await showDialog<Map<String, dynamic>>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(title: const Text('AI से नया टेस्ट बनाएँ'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: topicController, maxLength: 120, decoration: const InputDecoration(labelText: 'विषय / टॉपिक', hintText: 'जैसे: Ohm का नियम')), const SizedBox(height: 8), DropdownButtonFormField<int>(value: count, decoration: const InputDecoration(labelText: 'प्रश्नों की संख्या'), items: [3, 5, 10, 15].map((n) => DropdownMenuItem(value: n, child: Text('$n प्रश्न'))).toList(), onChanged: (v) { if (v != null) setDialogState(() => count = v); })]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('रद्द करें')), FilledButton(onPressed: () => Navigator.pop(dialogContext, {'topic': topicController.text.trim(), 'count': count}), child: const Text('बनाएँ'))])));
    if (request == null) { topicController.dispose(); return; }
    final topic = request['topic'] as String; final requestedCount = request['count'] as int; topicController.dispose();
    if (topic.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('पहले विषय लिखें।'))); return; }
    setState(() => _generating = true);
    try {
      final result = await AiTeacherService().generateQuiz(topic: topic, count: requestedCount);
      final generated = (result['questions'] as List).map((raw) { final item = Map<String, dynamic>.from(raw as Map); return PracticeQuestion(item['question'] as String, List<String>.from(item['options'] as List), item['answerIndex'] as int, item['explanation'] as String); }).toList();
      if (!mounted) return;
      setState(() { _activeQuestions = generated; _index = 0; _selected = null; _score = 0; _answered = false; _saving = false; _saved = false; _saveError = null; _responses.clear(); _isAiQuiz = true; });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI टेस्ट नहीं बन पाया: $e'))); }
    finally { if (mounted) setState(() => _generating = false); }
  }

  void _checkAnswer() {
    if (_selected == null || _answered) return;
    setState(() {
      _answered = true;
      _responses.add({
        'question': _current.question,
        'options': List<String>.from(_current.options),
        'selectedIndex': _selected!,
        'correctIndex': _current.answer,
        'explanation': _current.explanation,
      });
      if (_selected == _current.answer) _score++;
    });
  }

  void _next() {
    if (!_answered) return;
    if (_index == _activeQuestions.length - 1) {
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
        quizId: _isAiQuiz ? 'ai_generated_${DateTime.now().millisecondsSinceEpoch}' : 'starter_basics_01',
        score: _score,
        total: _questions.length,
        responses: List<Map<String, dynamic>>.from(_responses),
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
      _activeQuestions = List<PracticeQuestion>.from(_questions);
      _isAiQuiz = false;
      _selected = null;
      _score = 0;
      _answered = false;
      _saving = false;
      _saved = false;
      _saveError = null;
      _responses.clear();
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
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_isAiQuiz ? 'AI-generated अभ्यास • आधिकारिक PYQ नहीं' : 'शुरुआती अभ्यास सेट • नमूना प्रश्न, आधिकारिक PYQ नहीं', style: const TextStyle(fontSize: 15)), const SizedBox(height: 10), OutlinedButton.icon(onPressed: _generating ? null : _generateQuiz, icon: _generating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(_generating ? 'AI प्रश्न बना रहा है…' : 'AI से विषयवार टेस्ट बनाएँ'))]))),
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
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AiTeacherScreen(
                              mode: 'explain_question',
                              question: q.question,
                              selectedAnswer: q.options[_selected!],
                              correctAnswer: q.options[q.answer],
                              explanation: q.explanation,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.smart_toy_outlined),
                        label: const Text('AI से यह प्रश्न समझें'),
                      ),
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
