import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/adaptive_study_context.dart';

void main() {
  group('adaptive quiz study context', () {
    test('ranks topics with repeated incorrect answers first', () {
      final context = buildAdaptiveQuizContext(
        setupAnswers: {'school_class': '12', 'language': 'hi'},
        quizAttempts: [
          {
            'score': 1,
            'total': 3,
            'responses': [
              {'question': 'Ohm law Q1', 'topic': 'Ohm Law', 'selectedIndex': 0, 'correctIndex': 1},
              {'question': 'Ohm law Q2', 'topic': 'Ohm Law', 'selectedIndex': 1, 'correctIndex': 2},
              {'question': 'Math Q1', 'topic': 'Mathematics', 'selectedIndex': 0, 'correctIndex': 0},
            ],
          },
        ],
        priorTeacherQuestions: ['Current और Resistance में अंतर क्या है?'],
      );

      expect(context, contains('school_class: 12'));
      expect(context, contains('Ohm Law (2 गलत उत्तर)'));
      expect(context, contains('AI Teacher में विद्यार्थी के हाल के सवाल'));
      expect(context, contains('1/3 सही'));
    });

    test('ignores old responses without topic and keeps output bounded', () {
      final context = buildAdaptiveQuizContext(
        setupAnswers: {},
        quizAttempts: [
          {
            'responses': [
              {'question': 'पुराना प्रश्न', 'selectedIndex': 0, 'correctIndex': 1},
            ],
          },
        ],
        priorTeacherQuestions: List<String>.filled(30, 'विद्यार्थी का लंबा सवाल ' * 30),
      );

      expect(context, contains('पिछली गलतियाँ'));
      expect(context.length, lessThanOrEqualTo(3000));
    });

    test('returns an empty context when no learner history exists', () {
      expect(
        buildAdaptiveQuizContext(setupAnswers: {}, quizAttempts: []),
        isEmpty,
      );
    });
  });
}
