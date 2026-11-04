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
}
