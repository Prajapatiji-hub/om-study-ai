import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/profile_data_loader.dart';

void main() {
  group('loadProfileAndMemory', () {
    test('keeps profile available when AI Study Memory read is denied', () async {
      final result = await loadProfileAndMemory(
        loadProfile: () async => {
          'displayName': 'विद्यार्थी',
          'language': 'hi',
          'selectedGoals': ['school'],
        },
        loadMemory: () async => throw StateError('permission-denied'),
      );

      expect(result.profile?['displayName'], 'विद्यार्थी');
      expect(result.profile?['selectedGoals'], ['school']);
      expect(result.profileError, isNull);
      expect(result.memory, isNull);
      expect(result.memoryError, isA<StateError>());
    });

    test('keeps Memory available when profile read fails', () async {
      final result = await loadProfileAndMemory(
        loadProfile: () async => throw StateError('unavailable'),
        loadMemory: () async => {'summary': 'कक्षा 12'},
      );

      expect(result.profile, isNull);
      expect(result.profileError, isA<StateError>());
      expect(result.memory?['summary'], 'कक्षा 12');
      expect(result.memoryError, isNull);
    });

    test('returns both documents when both reads succeed', () async {
      final result = await loadProfileAndMemory(
        loadProfile: () async => {'displayName': 'Student'},
        loadMemory: () async => {'summary': 'Study goal'},
      );

      expect(result.profile?['displayName'], 'Student');
      expect(result.memory?['summary'], 'Study goal');
      expect(result.profileError, isNull);
      expect(result.memoryError, isNull);
    });
  });
}
