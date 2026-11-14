import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/ai_service_error.dart';

void main() {
  group('AI service error mapping', () {
    test('distinguishes an expired or rejected login', () {
      expect(aiServiceErrorMessage(statusCode: 401),
          'लॉगिन की पुष्टि नहीं हुई। दोबारा लॉगिन करें।');
    });

    test('distinguishes per-user throttling from provider quota exhaustion', () {
      expect(aiServiceErrorMessage(statusCode: 429, errorCode: 'rate_limited'),
          contains('एक मिनट'));
      expect(aiServiceErrorMessage(statusCode: 429, errorCode: 'resource_exhausted'),
          contains('उपयोग सीमा'));
    });

    test('explains closed rate-limit configuration without implying quota exhaustion', () {
      expect(
        aiServiceErrorMessage(statusCode: 503, errorCode: 'rate_limit_unavailable'),
        contains('सुरक्षा जाँच'),
      );
    });

    test('preserves safe server messages and supplies a quiz fallback', () {
      expect(aiServiceErrorMessage(statusCode: 503, serverMessage: 'सेवा रुकी है'),
          'सेवा रुकी है');
      expect(aiServiceErrorMessage(statusCode: 503, quiz: true),
          contains('AI प्रश्न'));
    });
  });
}
