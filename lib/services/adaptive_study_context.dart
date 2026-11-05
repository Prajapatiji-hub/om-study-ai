/// Returns true only for a well-formed, explicitly incorrect quiz response.
bool isIncorrectQuizResponse(Map response) {
  final selected = response['selectedIndex'];
  final correct = response['correctIndex'];
  return selected is int && correct is int && selected != correct;
}

/// Builds a compact, privacy-scoped learning profile for adaptive quiz generation.
String buildAdaptiveQuizContext({
  required Map<String, dynamic> setupAnswers,
  required List<Map<String, dynamic>> quizAttempts,
  Map<String, dynamic> curatedStudyMemory = const {},
  List<String> priorTeacherQuestions = const [],
  List<String> legacyTeacherQuestions = const [],
}) {
  final parts = <String>[];
  for (final key in [
    'goals', 'school_class', 'school_board', 'school_stream', 'govt_exam',
    'govt_year', 'iti_trade', 'language', 'hours', 'time', 'lesson_len',
    'school_level', 'govt_level', 'iti_level', 'school_hard',
  ]) {
    final value = setupAnswers[key];
    if (value is String && value.trim().isNotEmpty && value != '__skipped') {
      parts.add('विद्यार्थी की पढ़ाई सेटअप — $key: ${value.trim()}');
    } else if (value is List && value.isNotEmpty) {
      parts.add('विद्यार्थी की पढ़ाई सेटअप — $key: ${value.join(', ')}');
    }
  }

  // The student's editable private memory is shared with the AI Teacher.
  // Include the same bounded profile in quiz generation so manual strengths,
  // weak topics and explanation preferences are not lost between features.
  final memorySummary = curatedStudyMemory['summary'];
  if (memorySummary is String && memorySummary.trim().isNotEmpty) {
    final clean = memorySummary.trim();
    parts.add('विद्यार्थी की संपादित AI Study Memory: ${clean.length > 900 ? '${clean.substring(0, 900)}…' : clean}');
  }
  for (final entry in [
    ('मजबूत विषय (विद्यार्थी की पसंद)', curatedStudyMemory['strengths']),
    ('विद्यार्थी द्वारा बताए कमजोर विषय — पहले अभ्यास दें', curatedStudyMemory['weakTopics']),
  ]) {
    final values = entry.$2;
    if (values is List) {
      final clean = values
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .take(8)
          .map((value) => value.length > 60 ? '${value.substring(0, 60)}…' : value)
          .toList();
      if (clean.isNotEmpty) parts.add('${entry.$1}: ${clean.join(', ')}');
    }
  }
  final preferredStyle = curatedStudyMemory['preferredStyle'];
  if (preferredStyle is String && preferredStyle.trim().isNotEmpty) {
    final clean = preferredStyle.trim();
    parts.add('समझाने की पसंदीदा शैली: ${clean.length > 240 ? '${clean.substring(0, 240)}…' : clean}');
  }

  final weakTopics = <String, int>{};
  final mistakes = <String>[];
  final scoreSummaries = <String>[];
  for (final attempt in quizAttempts.take(5)) {
    final score = attempt['score'];
    final total = attempt['total'];
    if (score is num && total is num && total > 0) {
      scoreSummaries.add('${score.toInt()}/${total.toInt()} सही');
    }
    final rawResponses = attempt['responses'];
    if (rawResponses is! List) continue;
    for (final raw in rawResponses) {
      if (raw is! Map) continue;
      // Ignore malformed/legacy response rows instead of inventing a weakness.
      if (!isIncorrectQuizResponse(raw)) continue;
      final question = raw['question'];
      if (question is String && question.trim().isNotEmpty && mistakes.length < 8) {
        mistakes.add(question.trim());
      }
      final topic = raw['topic'] is String
          ? (raw['topic'] as String).trim()
          : (attempt['topic'] is String ? (attempt['topic'] as String).trim() : '');
      if (topic.isNotEmpty) weakTopics[topic] = (weakTopics[topic] ?? 0) + 1;
    }
  }

  if (scoreSummaries.isNotEmpty) {
    parts.add('पिछले टेस्ट के परिणाम (नए से पुराने): ${scoreSummaries.join(', ')}');
  }
  final rankedTopics = weakTopics.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  if (rankedTopics.isNotEmpty) {
    parts.add('कमजोर विषयों की प्राथमिकता: ${rankedTopics.take(5).map((e) => '${e.key} (${e.value} गलत उत्तर)').join(', ')}. इन विषयों पर पहले आसान, फिर मध्यम स्तर के प्रश्न दें।');
  }
  if (mistakes.isNotEmpty) {
    parts.add('पिछली गलतियाँ — इन्हीं अवधारणाओं की नई भाषा में जाँच करें, प्रश्न हूबहू न दोहराएँ: ${mistakes.take(5).join(' | ')}');
  }
  final questions = priorTeacherQuestions.where((v) => v.trim().isNotEmpty).take(6).toList();
  if (questions.isNotEmpty) {
    parts.add('AI Teacher में विद्यार्थी के हाल के सवाल: ${questions.join(' | ')}. संबंधित अवधारणाओं को क्विज में शामिल करें।');
  }
  final legacy = legacyTeacherQuestions.where((v) => v.trim().isNotEmpty).take(4).toList();
  if (legacy.isNotEmpty) {
    parts.add('पुरानी सुरक्षित AI Teacher बातचीत से सवाल: ${legacy.join(' | ')}');
  }

  final context = parts.join('\n');
  return context.length > 3000 ? context.substring(0, 3000) : context;
}
