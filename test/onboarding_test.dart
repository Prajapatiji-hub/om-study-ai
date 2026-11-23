import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/screens/onboarding.dart';
void main() {
  group('Study Setup question branching', () {
    test('school questions appear only when school goal is selected', () {
      final school = visibleQuestions({'goals': ['school']}).map((q) => q.id).toList();
      final noSchool = visibleQuestions({'goals': ['govt']}).map((q) => q.id).toList();
      expect(school, containsAll(['school_class', 'school_board', 'school_stream', 'school_level', 'school_hard']));
      expect(noSchool, isNot(contains('school_class')));
    });
    test('government and ITI questions are goal-specific', () {
      final govt = visibleQuestions({'goals': ['govt']}).map((q) => q.id).toList();
      final iti = visibleQuestions({'goals': ['iti']}).map((q) => q.id).toList();
      expect(govt, containsAll(['govt_exam', 'govt_year', 'govt_level', 'govt_syllabus']));
      expect(iti, containsAll(['iti_trade', 'iti_level', 'iti_mode']));
      expect(govt, isNot(contains('iti_trade')));
      expect(iti, isNot(contains('govt_exam')));
    });
    test('multi-goal learners receive both relevant question groups', () {
      final ids = visibleQuestions({'goals': ['school', 'iti']}).map((q) => q.id).toList();
      expect(ids, contains('school_class'));
      expect(ids, contains('iti_trade'));
      expect(ids, contains('language'));
    });
    test('progress counts only questions visible for selected goals', () {
      final progress = onboardingProgress({'goals': ['school'], 'school_class': '12', 'language': 'hi'});
      expect(progress.done, 3);
      expect(progress.total, visibleQuestions({'goals': ['school']}).length);
    });
  });
  group('saved Study Setup answer validation', () {
    test('single and multi answers must use known non-empty option values', () {
      final goals = kQuestions.firstWhere((question) => question.id == 'goals');
      final schoolClass = kQuestions.firstWhere((question) => question.id == 'school_class');

      expect(isValidStudySetupAnswer(goals, ['school']), isTrue);
      expect(isValidStudySetupAnswer(goals, []), isFalse);
      expect(isValidStudySetupAnswer(goals, ['unknown']), isFalse);
      expect(isValidStudySetupAnswer(goals, ['school', 'school']), isFalse);
      expect(isValidStudySetupAnswer(schoolClass, '12'), isTrue);
      expect(isValidStudySetupAnswer(schoolClass, '13'), isFalse);
      expect(isValidStudySetupAnswer(schoolClass, '__skipped'), isFalse);
    });

    test('optional skips are accepted only for optional questions', () {
      final optional = kQuestions.firstWhere((question) => question.id == 'school_hard');
      final required = kQuestions.firstWhere((question) => question.id == 'language');

      expect(isValidStudySetupAnswer(optional, '__skipped'), isTrue);
      expect(isValidStudySetupAnswer(optional, '  '), isFalse);
      expect(isValidStudySetupAnswer(required, '__skipped'), isFalse);
    });

    test('text answers must be non-blank and stay within the UI limit', () {
      final question = kQuestions.firstWhere((item) => item.id == 'govt_year');
      expect(isValidStudySetupAnswer(question, '2027'), isTrue);
      expect(isValidStudySetupAnswer(question, '   '), isFalse);
      expect(isValidStudySetupAnswer(question, 'x' * 201), isFalse);
    });

    test('completion checks every visible answer and routes invalid values back', () {
      final answers = <String, dynamic>{'goals': ['school']};
      for (final question in visibleQuestions(answers)) {
        if (question.id == 'goals') continue;
        if (question.type == 'single') {
          answers[question.id] = question.options.keys.first;
        } else if (question.type == 'text') {
          answers[question.id] = question.optional ? '__skipped' : 'valid';
        }
      }

      expect(hasCompletedVisibleStudySetup(answers), isTrue);
      answers['school_class'] = 'invalid-class';
      expect(hasCompletedVisibleStudySetup(answers), isFalse);
      expect(firstUnansweredVisibleStudySetupQuestionIndex(answers), 1);
    });

    test('progress counts only valid saved answers, not present-but-invalid keys', () {
      final progress = onboardingProgress({
        'goals': [],
        'school_class': '12',
        'language': 'hi',
      });
      expect(progress.done, 1);
      expect(progress.total, visibleQuestions({'goals': []}).length);
    });
  });

}
