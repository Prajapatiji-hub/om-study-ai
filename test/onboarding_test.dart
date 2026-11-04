import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/screens/onboarding.dart';

void main() {
  group('onboarding question visibility', () {
    test('school goal shows school questions but hides unrelated tracks', () {
      final questions = visibleQuestions({'goals': ['school']});
      final ids = questions.map((question) => question.id).toSet();

      expect(ids, contains('school_class'));
      expect(ids, contains('school_board'));
      expect(ids, contains('language'));
      expect(ids, isNot(contains('govt_exam')));
      expect(ids, isNot(contains('iti_trade')));
    });

    test('progress counts only visible answered questions', () {
      final answers = {
        'goals': ['school'],
        'school_class': '12',
        'govt_exam': 'ssc',
      };

      final progress = onboardingProgress(answers);

      expect(progress.done, 2);
      expect(progress.total, visibleQuestions(answers).length);
    });

    test('no selected goal hides all track-specific questions', () {
      final ids = visibleQuestions({'goals': <String>[]})
          .map((question) => question.id)
          .toSet();

      expect(ids, isNot(contains('school_class')));
      expect(ids, isNot(contains('govt_exam')));
      expect(ids, isNot(contains('iti_trade')));
      expect(ids, contains('language'));
    });
  });
}
