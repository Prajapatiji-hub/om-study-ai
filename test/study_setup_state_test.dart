import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/study_setup_state.dart';
void main() {
  group('required Study Setup gate', () {
    test('blocks only when the explicit marker is true', () {
      expect(isRequiredStudySetupPending({'_setupRequired': true}), isTrue);
      expect(isRequiredStudySetupPending({'_setupRequired': false}), isFalse);
      expect(isRequiredStudySetupPending({}), isFalse);
      expect(isRequiredStudySetupPending({'_setupRequired': 'true'}), isFalse);
    });
    test('does not infer a setup requirement from existing learner answers', () {
      expect(isRequiredStudySetupPending({'goals': ['school'], 'school_class': '12', 'language': 'hi'}), isFalse);
    });
  });
}
