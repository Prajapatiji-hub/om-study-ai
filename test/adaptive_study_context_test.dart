import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/adaptive_study_context.dart';

void main() {
  group('isIncorrectQuizResponse', () {
    test('accepts only two integer indexes that differ', () {
      expect(isIncorrectQuizResponse({'selectedIndex': 0, 'correctIndex': 1}), isTrue);
      expect(isIncorrectQuizResponse({'selectedIndex': 1, 'correctIndex': 1}), isFalse);
      expect(isIncorrectQuizResponse({'selectedIndex': null, 'correctIndex': null}), isFalse);
      expect(isIncorrectQuizResponse({'selectedIndex': null, 'correctIndex': 1}), isFalse);
      expect(isIncorrectQuizResponse({'selectedIndex': '0', 'correctIndex': 1}), isFalse);
      expect(isIncorrectQuizResponse({}), isFalse);
    });
  });


