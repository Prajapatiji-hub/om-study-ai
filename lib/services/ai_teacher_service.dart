import 'package:cloud_functions/cloud_functions.dart';

class AiTeacherService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  Future<String> ask({
    required String message,
    String mode = 'tutor',
    String question = '',
    String selectedAnswer = '',
    String correctAnswer = '',
    String explanation = '',
    List<Map<String, String>> history = const [],
  }) async {
    final callable = _functions.httpsCallable(
      'askStudyTeacher',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 65)),
    );
    final result = await callable.call({
      'mode': mode,
      'message': message,
      'question': question,
      'selectedAnswer': selectedAnswer,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'history': history.take(8).toList(),
    });
    final data = result.data;
    if (data is! Map || data['answer'] is! String) {
      throw StateError('AI से सही जवाब नहीं मिला।');
    }
    return (data['answer'] as String).trim();
  }
}
