/// Builds a compact, privacy-scoped learning profile for adaptive quiz generation.
String buildAdaptiveQuizContext({
  required Map<String, dynamic> setupAnswers,
  required List<Map<String, dynamic>> quizAttempts,
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
      final selected = raw['selectedIndex'];
      final correct = raw['correctIndex'];
      // Ignore malformed/legacy response rows instead of treating two missing
      // indexes as a correct answer or inventing a weakness.
      if (selected is! int || correct is! int || selected == correct) continue;
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
