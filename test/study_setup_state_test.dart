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


}
