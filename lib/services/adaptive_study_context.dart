/// Returns true only for a well-formed, explicitly incorrect quiz response.
bool isIncorrectQuizResponse(Map response) {
  final selected = response['selectedIndex'];
  final correct = response['correctIndex'];
  return selected is int && correct is int && selected != correct;
}


/// Uses the editable profile language first, then the original Study Setup
/// answer for older accounts that do not yet have a profile language field.
String? resolveStudyLanguage({
  required Map<String, dynamic> profile,
  required Map<String, dynamic> setupAnswers,
}) {
  const supported = {'hi', 'en', 'hinglish'};
  final profileLanguage = profile['language'];
  if (profileLanguage is String && supported.contains(profileLanguage)) {
    return profileLanguage;
  }
  final setupLanguage = setupAnswers['language'];
  if (setupLanguage is String && supported.contains(setupLanguage)) {
    return setupLanguage;
  }
  return null;
}

/// Resolves the student's goals without losing older profile-only data.
/// Explicit Study Setup answers take precedence; legacy profile goals are a fallback.
List<String> resolveStudyGoals({
  required Map<String, dynamic> profile,
  required Map<String, dynamic> setupAnswers,
}) {
  List<String> cleanGoals(dynamic raw) {
    if (raw is! List) return <String>[];
    final seen = <String>{};
    return raw
        .whereType<String>()
        .map((goal) => goal.trim())
        .where((goal) => goal.isNotEmpty && seen.add(goal))
        .take(8)
        .map((goal) => goal.length > 80 ? '${goal.substring(0, 80)}…' : goal)
        .toList();
  }

  final setupGoals = cleanGoals(setupAnswers['goals']);
  return setupGoals.isNotEmpty
      ? setupGoals
      : cleanGoals(profile['selectedGoals']);
}

/// Extracts only student-authored legacy chat prompts from a newest-first
/// Firestore page, returning them in chronological order for quiz context.
/// Assistant answers are deliberately excluded so they cannot become fake
/// student questions or bias adaptive quiz generation.
List<String> extractLegacyStudentQuestionsFromNewestFirst(
  List<Map<String, dynamic>> newestFirstMessages, {
  int maxQuestions = 4,
  int maxCharacters = 220,
}) {
  if (maxQuestions <= 0 || maxCharacters <= 0) return <String>[];
  final seen = <String>{};
  final questions = <String>[];
  for (final message in newestFirstMessages.reversed) {
    if (message['role'] != 'user') continue;
    final rawText = message['text'];
    if (rawText is! String) continue;
    final clean = rawText.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty || !seen.add(clean)) continue;
    questions.add(clean.length > maxCharacters
        ? '${clean.substring(0, maxCharacters)}…'
        : clean);
    if (questions.length >= maxQuestions) break;
  }
  return questions;
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
      if (key == 'language') {
        // The Worker reads this stable field to choose Hindi, English or Hinglish.
        parts.add('language: ${value.trim()}');
      } else {
        parts.add('विद्यार्थी की पढ़ाई सेटअप — $key: ${value.trim()}');
      }
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

/// Summarizes only this student's recent, explicitly incorrect quiz responses
/// for AI Teacher personalization. Correct or malformed answers never create
/// a weak-topic signal; the result is kept small for the Worker request.
String buildRecentQuizLearningSummary(
  List<Map<String, dynamic>> quizAttempts, {
  int maxAttempts = 3,
}) {
  final scoreSummaries = <String>[];
  final weakTopics = <String, int>{};
  final mistakes = <String>[];
  final seenQuestions = <String>{};

  for (final attempt in quizAttempts.take(maxAttempts < 0 ? 0 : maxAttempts)) {
    final score = attempt['score'];
    final total = attempt['total'];
    if (score is num && total is num && total > 0 && score >= 0 && score <= total) {
      scoreSummaries.add('${score.toInt()}/${total.toInt()} सही');
    }

    final responses = attempt['responses'];
    if (responses is! List) continue;
    for (final raw in responses) {
      if (raw is! Map || !isIncorrectQuizResponse(raw)) continue;

      final question = raw['question'];
      if (question is String && question.trim().isNotEmpty) {
        final clean = question.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (seenQuestions.add(clean) && mistakes.length < 5) {
          mistakes.add(clean.length > 140 ? '${clean.substring(0, 140)}…' : clean);
        }
      }

      final responseTopic = raw['topic'];
      final attemptTopic = attempt['topic'];
      final topic = responseTopic is String && responseTopic.trim().isNotEmpty
          ? responseTopic.trim()
          : (attemptTopic is String ? attemptTopic.trim() : '');
      if (topic.isNotEmpty) {
        final cleanTopic = topic.length > 60 ? topic.substring(0, 60) : topic;
        weakTopics[cleanTopic] = (weakTopics[cleanTopic] ?? 0) + 1;
      }
    }
  }

  final parts = <String>[];
  if (scoreSummaries.isNotEmpty) {
    parts.add('हाल के टेस्ट के स्कोर (नए से पुराने): ${scoreSummaries.join(', ')}');
  }
  final rankedTopics = weakTopics.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  if (rankedTopics.isNotEmpty) {
    parts.add('क्विज में बार-बार गलत विषय: ${rankedTopics.take(5).map((e) => '${e.key} (${e.value} गलत)').join(', ')}');
  }
  if (mistakes.isNotEmpty) {
    parts.add('हाल के गलत प्रश्न: ${mistakes.join(' | ')}');
  }

  final summary = parts.join('\n');
  return summary.length > 1200 ? summary.substring(0, 1200) : summary;
}