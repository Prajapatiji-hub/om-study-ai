import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/study_setup_state.dart';

void main() {
  group('fail-closed Study Setup dashboard access', () {
    test('loading never releases the dashboard before the first snapshot', () {
      expect(
        resolveStudySetupAccess(hasData: false, hasError: false),
        StudySetupAccessState.loading,
      );
    });

    test('a read error blocks access even if a cached completed value exists', () {
      expect(
        resolveStudySetupAccess(
          hasData: true,
          hasError: true,
          answers: {'_setupRequired': false},
        ),
        StudySetupAccessState.error,
      );
    });

    test('a new account with a required marker is routed to Study Setup', () {
      expect(
        resolveStudySetupAccess(
          hasData: true,
          hasError: false,
          answers: {'_setupRequired': true},
        ),
        StudySetupAccessState.setupRequired,
      );
    });

    test('an explicitly completed account can enter the dashboard', () {
      expect(
        resolveStudySetupAccess(
          hasData: true,
          hasError: false,
          answers: {'_setupRequired': false},
        ),
        StudySetupAccessState.allowed,
      );
    });

    test('legacy accounts without a marker retain dashboard access', () {
      expect(
        resolveStudySetupAccess(
          hasData: true,
          hasError: false,
          answers: {'goals': ['school'], 'language': 'hi'},
        ),
        StudySetupAccessState.allowed,
      );
    });

    test('a loaded empty legacy answers document is not mistaken for a new signup', () {
      expect(
        resolveStudySetupAccess(
          hasData: true,
          hasError: false,
          answers: const {},
        ),
        StudySetupAccessState.allowed,
      );
    });
  });
}
