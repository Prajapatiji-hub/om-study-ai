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

    test("includes the same student's editable AI Study Memory in quiz context", () {
      final context = buildAdaptiveQuizContext(
        setupAnswers: {'language': 'hi'},
        quizAttempts: [],
        curatedStudyMemory: {
          'summary': 'मैं कक्षा 12 की बोर्ड परीक्षा की तैयारी कर रहा हूँ।',
          'strengths': ['गणित', 'भौतिकी'],
          'weakTopics': ['त्रिकोणमिति', 'ओम का नियम'],
          'preferredStyle': 'आसान हिंदी और चरण-दर-चरण उदाहरण',
        },
      );

      expect(context, contains('संपादित AI Study Memory'));
      expect(context, contains('कक्षा 12'));
      expect(context, contains('मजबूत विषय'));
      expect(context, contains('त्रिकोणमिति'));
      expect(context, contains('ओम का नियम'));
      expect(context, contains('चरण-दर-चरण'));
    });

    test('bounds oversized editable memory and ignores malformed memory fields', () {
      final context = buildAdaptiveQuizContext(
        setupAnswers: {},
        quizAttempts: [],
        curatedStudyMemory: {
          'summary': 'स' * 5000,
          'strengths': ['गणित', 42, 'भौतिकी'],
          'weakTopics': 'यह सूची नहीं है',
          'preferredStyle': 'ह' * 500,
        },
      );

      expect(context.length, lessThanOrEqualTo(3000));
      expect(context, contains('गणित'));
      expect(context, isNot(contains('42')));
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

    test('ignores malformed answer indexes when ranking weak topics', () {
      final context = buildAdaptiveQuizContext(
        setupAnswers: {},
        quizAttempts: [
          {
            'responses': [
              {'question': 'Malformed', 'topic': 'Unknown', 'selectedIndex': null, 'correctIndex': null},
              {'question': 'Valid wrong', 'topic': 'Physics', 'selectedIndex': 1, 'correctIndex': 2},
            ],
          },
        ],
      );

      expect(context, contains('Physics (1 गलत उत्तर)'));
      expect(context, isNot(contains('Unknown')));
    });

    test('returns an empty context when no learner history exists', () {
      expect(
        buildAdaptiveQuizContext(setupAnswers: {}, quizAttempts: []),
        isEmpty,
      );
    });
  });
}
