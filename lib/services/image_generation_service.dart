import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'ai_service_error.dart';
import 'image_generation_policy.dart';

class ImageGenerationService {
  static const String _workerUrl =
      String.fromEnvironment('AI_WORKER_URL', defaultValue: '');

  bool get isConfigured => isValidImageWorkerUrl(_workerUrl);

  Future<Uint8List> generate(String rawPrompt) async {
    final prompt = validateImagePrompt(rawPrompt);
    if (!isConfigured) {
      throw StateError('AI backend का Free setup अभी पूरा नहीं हुआ है।');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('चित्र बनाने के लिए पहले लॉगिन करें।');
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
          body: jsonEncode({'mode': 'generate_image', 'prompt': prompt}),
        )
        .timeout(const Duration(seconds: 120));

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      // The safe error message below handles non-JSON provider responses.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(aiServiceErrorMessage(
        statusCode: response.statusCode,
        errorCode: data['error'] is String ? data['error'] as String : null,
        serverMessage: data['message'] is String ? data['message'] as String : null,
      ));
    }

    try {
      return decodeGeneratedImagePayload(data);
    } on FormatException {
      throw StateError('चित्र सही प्रारूप में नहीं मिला। फिर कोशिश करें।');
    }
  }
}
