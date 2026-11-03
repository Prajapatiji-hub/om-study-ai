import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../services/user_repo.dart';
import '../theme.dart';

const kSkipped = '__skipped';

class Q {
  final String id, text, type; // type: single | multi | text
  final Map<String, String> options;
  final bool optional;
  final bool Function(Map<String, dynamic>) show;
  Q(this.id, this.text, this.type,
      {this.options = const {}, this.optional = false, bool Function(Map<String, dynamic>)? show})
      : show = show ?? ((_) => true);
}

bool _has(Map<String, dynamic> a, String goal) =>
    (a['goals'] is List) && (a['goals'] as List).contains(goal);

const _level = {'beginner': 'शुरुआती', 'medium': 'ठीक-ठाक', 'good': 'अच्छा'};

final List<Q> kQuestions = [
  Q('goals', 'आप किस चीज़ की पढ़ाई करना चाहते हैं? (एक से ज़्यादा चुन सकते हैं)', 'multi',
      options: {'school': 'स्कूल की पढ़ाई', 'govt': 'सरकारी परीक्षा', 'iti': 'ITI / हुनर (Skill)'}),
  // School
  Q('school_class', 'आप किस क्लास में हैं?', 'single',
      options: {'10': 'क्लास 10', '11': 'क्लास 11', '12': 'क्लास 12'}, show: (a) => _has(a, 'school')),
  Q('school_board', 'आपका बोर्ड कौन-सा है?', 'single',
      options: {'jac': 'JAC', 'cbse': 'CBSE', 'bseb': 'बिहार बोर्ड', 'other': 'दूसरा'},
      show: (a) => _has(a, 'school')),
  Q('school_stream', 'आपकी स्ट्रीम कौन-सी है?', 'single',
      options: {'pcm': 'साइंस (PCM)', 'pcb': 'साइंस (PCB)', 'commerce': 'कॉमर्स', 'arts': 'आर्ट्स', 'none': 'क्लास 10 / लागू नहीं'},
      show: (a) => _has(a, 'school')),
  Q('school_level', 'पढ़ाई में आपका अभी का स्तर कैसा है?', 'single',
      options: _level, show: (a) => _has(a, 'school')),
  Q('school_hard', 'कौन-से विषय या चैप्टर मुश्किल लगते हैं?', 'text',
      optional: true, show: (a) => _has(a, 'school')),
  // Govt
  Q('govt_exam', 'किस परीक्षा की तैयारी करनी है?', 'single',
      options: {
        'rrb_alp': 'रेलवे ALP',
        'rrb_tech': 'रेलवे टेक्नीशियन',
        'ssc': 'SSC',
        'jharkhand': 'झारखंड की सरकारी परीक्षाएँ',
        'other': 'दूसरी'
      },
      show: (a) => _has(a, 'govt')),
  Q('govt_year', 'कौन-से साल की परीक्षा का लक्ष्य है?', 'text',
      optional: true, show: (a) => _has(a, 'govt')),
  Q('govt_level', 'तैयारी का अभी का स्तर कैसा है?', 'single',
      options: _level, show: (a) => _has(a, 'govt')),
  Q('govt_syllabus', 'क्या आपने सिलेबस पढ़ा है?', 'single',
      options: {'yes': 'हाँ', 'partly': 'थोड़ा', 'no': 'नहीं'}, show: (a) => _has(a, 'govt')),
  // ITI
  Q('iti_trade', 'कौन-सा हुनर / ट्रेड सीखना है?', 'single',
      options: {
        'electrician': 'इलेक्ट्रीशियन',
        'asst_electrician': 'असिस्टेंट इलेक्ट्रीशियन',
        'solar': 'सोलर इंस्टॉलेशन',
        'other': 'दूसरा'
      },
      show: (a) => _has(a, 'iti')),
  Q('iti_level', 'इस काम का आपका अनुभव कितना है?', 'single',
      options: {'none': 'बिल्कुल नहीं', 'some': 'थोड़ा', 'good': 'काफ़ी'}, show: (a) => _has(a, 'iti')),
  Q('iti_mode', 'आप क्या सीखना चाहते हैं?', 'single',
      options: {'theory': 'सिर्फ़ थ्योरी', 'practical': 'प्रैक्टिकल समझ', 'both': 'दोनों'},
      show: (a) => _has(a, 'iti')),
  // Preferences
  Q('language', 'आप किस भाषा में पढ़ना चाहते हैं?', 'single',
      options: {'hi': 'हिंदी', 'en': 'English', 'hinglish': 'Hinglish'}),
  Q('hours', 'रोज़ कितने घंटे पढ़ सकते हैं?', 'single',
      options: {'1': '1 घंटा', '2': '2 घंटे', '3': '3 घंटे', '4plus': '4 घंटे या ज़्यादा'}),
  Q('time', 'पढ़ने का पसंदीदा समय कौन-सा है?', 'single',
      options: {'morning': 'सुबह', 'afternoon': 'दोपहर', 'evening': 'शाम', 'night': 'रात'}),
  Q('start', 'पढ़ाई कब से शुरू करना चाहते हैं?', 'single',
      options: {'today': 'आज से', 'tomorrow': 'कल से', 'monday': 'अगले सोमवार से'}),
  Q('lesson_len', 'कैसे पाठ पसंद हैं?', 'single',
      options: {'short': 'छोटे पाठ', 'detailed': 'विस्तार से'}),
  Q('tests', 'क्या नियमित टेस्ट चाहिए?', 'single', options: {'yes': 'हाँ', 'no': 'नहीं'}),
  Q('revision', 'दोहराई (Revision) कितनी बार रखें?', 'single',
      options: {'weekly': 'हर हफ़्ते', 'biweekly': 'हर 15 दिन', 'monthly': 'हर महीने'}),
  Q('internet', 'क्या आपके पास हमेशा इंटरनेट रहता है?', 'single',
      options: {'always': 'हाँ, हमेशा', 'sometimes': 'कभी-कभी', 'mostly_offline': 'ज़्यादातर नहीं'}),
];

List<Q> visibleQuestions(Map<String, dynamic> a) =>
    kQuestions.where((q) => q.show(a)).toList();

({int done, int total}) onboardingProgress(Map<String, dynamic> a) {
  final v = visibleQuestions(a);
  return (done: v.where((q) => a.containsKey(q.id)).length, total: v.length);
}

class OnboardingScreen extends StatefulWidget {
  final UserRepo repo;
  final bool edit; // true = start from first question to change answers
  final bool requiredForNewAccount;
  const OnboardingScreen({super.key, required this.repo, this.edit = false, this.requiredForNewAccount = false});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Map<String, dynamic> _answers = {};
  int _idx = 0;
  bool _loading = true, _saving = false;
  String? _error;
  List<String> _multi = [];
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _answers = Map<String, dynamic>.from(await widget.repo.loadAnswers());
      final v = visibleQuestions(_answers);
      _idx = widget.edit ? 0 : v.indexWhere((q) => !_answers.containsKey(q.id));
      if (_idx < 0) _idx = v.length;
      _prime();
    } catch (_) {
      _error = 'जवाब लोड नहीं हो सके। इंटरनेट जाँचकर दोबारा खोलें।';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _prime() {
    final v = visibleQuestions(_answers);
    _multi = [];
    _text.text = '';
    if (_idx < v.length) {
      final q = v[_idx];
      final cur = _answers[q.id];
      if (q.type == 'multi' && cur is List) _multi = List<String>.from(cur);
      if (q.type == 'text' && cur is String && cur != kSkipped) _text.text = cur;
    }
  }

  Future<void> _save(Q q, dynamic value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.saveAnswer(q.id, value); // saved immediately to this user's account
      _answers[q.id] = value;
      if (q.id == 'goals') await widget.repo.updateProfile({'selectedGoals': value});
      if (q.id == 'language') await widget.repo.updateProfile({'language': value});
      _idx++;
      _prime();
    } catch (e) {
      final code = e is FirebaseException ? e.code : e.runtimeType.toString();
      _error = 'सहेजा नहीं जा सका (कारण: $code)। दोबारा कोशिश करें।';
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
          appBar: AppBar(title: const Text('सेटअप')),
          body: const Center(child: CircularProgressIndicator()));
    }
    final v = visibleQuestions(_answers);
    final finished = _idx >= v.length;
    return PopScope(
      canPop: !widget.requiredForNewAccount,
      child: Scaffold(
        appBar: AppBar(title: const Text('आपकी पढ़ाई का सेटअप')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: finished ? _done() : _question(v[_idx], v.length),
          ),
        ),
      ),
    );
  }

  Future<void> _finishSetup() async {
    setState(() { _saving = true; _error = null; });
    try {
      await widget.repo.completeRequiredSetup();
      if (mounted && !widget.requiredForNewAccount) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = 'सेटअप पूरा नहीं हो सका। इंटरनेट जाँचकर फिर कोशिश करें।');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _done() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, size: 72, color: kTeal),
          const SizedBox(height: 16),
          const Text('सेटअप पूरा हुआ!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('जवाब कभी भी प्रोफ़ाइल से बदल सकते हैं।',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
          const SizedBox(height: 24),
          if (_error != null) Text(_error!, style: const TextStyle(color: kError)),
          FilledButton(
              onPressed: _saving ? null : _finishSetup,
              child: _saving ? const CircularProgressIndicator() : const Text('डैशबोर्ड पर जाएँ')),
        ],
      );

  Widget _question(Q q, int total) {
    return ListView(
      children: [
        LinearProgressIndicator(value: _idx / total, minHeight: 8),
        const SizedBox(height: 6),
        Text('सवाल ${_idx + 1} / $total', style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 20),
        Text(q.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        if (q.type == 'single')
          ...q.options.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _answers[q.id] == e.key
                    ? FilledButton(
                        onPressed: _saving ? null : () => _save(q, e.key), child: Text(e.value))
                    : OutlinedButton(
                        onPressed: _saving ? null : () => _save(q, e.key), child: Text(e.value)),
              )),
        if (q.type == 'multi') ...[
          ...q.options.entries.map((e) => CheckboxListTile(
                value: _multi.contains(e.key),
                title: Text(e.value, style: const TextStyle(fontSize: 18)),
                onChanged: (on) => setState(() {
                  on == true ? _multi.add(e.key) : _multi.remove(e.key);
                }),
              )),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: (_saving || _multi.isEmpty) ? null : () => _save(q, List<String>.from(_multi)),
              child: const Text('आगे बढ़ें')),
        ],
        if (q.type == 'text') ...[
          TextField(
            controller: _text,
            maxLength: 200,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'यहाँ लिखें'),
          ),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: _saving || _text.text.trim().isEmpty ? null : () => _save(q, _text.text.trim()),
              child: const Text('सहेजें')),
        ],
        if (q.optional) ...[
          const SizedBox(height: 10),
          TextButton(
              onPressed: _saving ? null : () => _save(q, kSkipped),
              child: const Text('यह सवाल छोड़ें', style: TextStyle(fontSize: 17))),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: kError, fontSize: 16)),
          ),
        if (_idx > 0)
          TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _idx--;
                        _prime();
                      }),
              child: const Text('पिछला सवाल', style: TextStyle(fontSize: 17))),
      ],
    );
  }
}
