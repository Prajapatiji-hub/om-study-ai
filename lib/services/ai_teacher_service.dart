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
      throw StateError('Gemini की मुफ्त उपयोग सीमा अभी पूरी हुई है। बाद में कोशिश करें।');
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
}
