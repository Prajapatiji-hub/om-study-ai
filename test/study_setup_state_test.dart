import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/study_setup_state.dart';

void main() {
  group('new-account setup marker decision', () {
    test('marks only accounts with neither a profile nor saved setup answers', () {
      expect(
        shouldCreateRequiredStudySetupMarker(
          profileExists: false,
          setupAnswersExist: false,
        ),
        isTrue,
      );
    });

    test('does not force setup for an existing profile', () {
      expect(
        shouldCreateRequiredStudySetupMarker(
          profileExists: true,
          setupAnswersExist: false,
        ),
        isFalse,
      );
    });

    test('preserves existing setup answers even when the profile is missing', () {
      expect(
        shouldCreateRequiredStudySetupMarker(
          profileExists: false,
          setupAnswersExist: true,
        ),
        isFalse,
      );
    });

    test('does not replace data when both documents already exist', () {
      expect(
        shouldCreateRequiredStudySetupMarker(
          profileExists: true,
          setupAnswersExist: true,
        ),
        isFalse,
      );
    });
  });

  group('required Study Setup gate', () {
    test('blocks only when the explicit marker is true', () {
      expect(isRequiredStudySetupPending({'_setupRequired': true}), isTrue);
      expect(isRequiredStudySetupPending({'_setupRequired': false}), isFalse);
      expect(isRequiredStudySetupPending({}), isFalse);
      expect(isRequiredStudySetupPending({'_setupRequired': 'true'}), isFalse);
    });

    test('does not infer a setup requirement from existing learner answers', () {
      expect(isRequiredStudySetupPending({
        'goals': ['school'],
        'school_class': '12',
        'language': 'hi',
      }), isFalse);
    });
  });

  group('required setup completion', () {
    test('finds the first unanswered visible question', () {
      expect(
        firstUnansweredStudySetupQuestionIndex(
          ['goals', 'school_class', 'language'],
          {'goals': ['school'], 'language': 'hi'},
        ),
        1,
      );
    });

    test('accepts an explicit skip for an optional question', () {
      final ids = ['goals', 'school_hard', 'language'];
      final answers = {
        'goals': ['school'],
        'school_hard': '__skipped',
        'language': 'hi',
      };
      expect(hasCompletedRequiredStudySetup(ids, answers), isTrue);
      expect(firstUnansweredStudySetupQuestionIndex(ids, answers), -1);
    });

    test('ignores hidden branch questions but requires every selected branch', () {
      final schoolIds = ['goals', 'school_class', 'school_board', 'language'];
      expect(
        hasCompletedRequiredStudySetup(
          schoolIds,
          {'goals': ['school'], 'school_class': '12', 'language': 'hi'},
        ),
        isFalse,
      );
      expect(
        hasCompletedRequiredStudySetup(
          ['goals', 'iti_trade', 'language'],
          {'goals': ['iti'], 'iti_trade': 'electrician', 'language': 'hi'},
        ),
        isTrue,
      );
    });

    test('does not mark an empty or incomplete setup complete', () {
      expect(hasCompletedRequiredStudySetup([], {}), isFalse);
      expect(hasCompletedRequiredStudySetup(['goals', 'language'], {'goals': ['school']}), isFalse);
    });
  });
}
