import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AiTeacherService {
  static const String _workerUrl =
      String.fromEnvironment('AI_WORKER_URL', defaultValue: '');

  Future<String> ask({
    required String message,
    String mode = 'tutor',
    String question = '',
    String selectedAnswer = '',
    String correctAnswer = '',
    String explanation = '',
    List<Map<String, String>> history = const [],
    String studyMemory = '',
    String topic = '',
    int quizCount = 5,
  }) async {
    if (_workerUrl.isEmpty || !_workerUrl.startsWith('https://')) {
      throw StateError('AI backend का Free setup अभी पूरा नहीं हुआ है।');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('AI टीचर इस्तेमाल करने के लिए पहले लॉगिन करें।');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('लॉगिन की पुष्टि नहीं हो पाई। दोबारा लॉगिन करें।');
    }

    final response = await http
        .post(
          Uri.parse(_workerUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'mode': mode,
            'message': message,
            'question': question,
            'selectedAnswer': selectedAnswer,
            'correctAnswer': correctAnswer,
            'explanation': explanation,
            'history': history.take(8).toList(),
            'studyMemory': studyMemory,
            'topic': topic,
            'count': quizCount,
          }),
        )
        .timeout(const Duration(seconds: 60));

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      // Use the friendly fallback below for a non-JSON response.
    }

    if (response.statusCode == 401) {
      throw StateError('लॉगिन की पुष्टि नहीं हुई। दोबारा लॉगिन करें।');
    }
    if (response.statusCode == 429) {
      throw StateError(data['error'] == 'rate_limited'
          ? 'आपने थोड़े समय में बहुत अनुरोध किए हैं। एक मिनट बाद फिर कोशिश करें।'
          : 'AI की उपयोग सीमा अभी पूरी हुई है। बाद में कोशिश करें।');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['message'];
      throw StateError(message is String
          ? message
          : 'AI सेवा अभी उपलब्ध नहीं है। बाद में कोशिश करें।');
    }
    if (data['answer'] is! String) {
      throw StateError('AI से सही जवाब नहीं मिला।');
    }
    return (data['answer'] as String).trim();
  }

  Future<Map<String, dynamic>> generateQuiz({
    required String topic,
    required int count,
    String studyMemory = '',
  }) async {
    if (_workerUrl.isEmpty || !_workerUrl.startsWith('https://')) {
      throw StateError('AI backend का Free setup अभी पूरा नहीं हुआ है।');
    }
    if (topic.trim().isEmpty || topic.trim().length > 120 || count < 3 || count > 15) {
      throw ArgumentError('विषय लिखें और 3 से 15 प्रश्न चुनें।');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('पहले लॉगिन करें।');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw StateError('लॉगिन की पुष्टि नहीं हुई।');
    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'mode': 'generate_quiz',
        'message': 'इस विषय पर अभ्यास प्रश्न बनाओ: ${topic.trim()}',
        'topic': topic.trim(),
        'count': count,
        'studyMemory': studyMemory,
      }),
    ).timeout(const Duration(seconds: 90));
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['message'];
      throw StateError(message is String ? message : 'AI प्रश्न अभी नहीं बना पाया।');
    }
    final quiz = data['quiz'];
    if (quiz is! Map<String, dynamic> || quiz['questions'] is! List ||
        (quiz['questions'] as List).length != count) {
      throw StateError('AI प्रश्नों का प्रारूप सही नहीं है। फिर कोशिश करें।');
    }
    for (final raw in quiz['questions'] as List) {
      if (raw is! Map || raw['question'] is! String || raw['options'] is! List ||
          (raw['options'] as List).length != 4 ||
          (raw['options'] as List).any((v) => v is! String) ||
          raw['answerIndex'] is! int || raw['answerIndex'] < 0 || raw['answerIndex'] > 3 ||
          raw['explanation'] is! String || raw['topic'] is! String) {
        throw StateError('AI प्रश्नों की जाँच पूरी नहीं हुई। फिर कोशिश करें।');
      }
    }
    return Map<String, dynamic>.from(quiz);
  }

}
