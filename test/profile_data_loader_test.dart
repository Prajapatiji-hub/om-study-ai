import 'dart:async';
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

    test('starts profile and memory reads concurrently', () async {
      final profileGate = Completer<Map<String, dynamic>>();
      final memoryGate = Completer<Map<String, dynamic>>();
      var profileStarted = false;
      var memoryStarted = false;

      final pending = loadProfileAndMemory(
        loadProfile: () {
          profileStarted = true;
          return profileGate.future;
        },
        loadMemory: () {
          memoryStarted = true;
          return memoryGate.future;
        },
      );

      expect(profileStarted, isTrue);
      expect(memoryStarted, isTrue);

      memoryGate.complete({'summary': 'कक्षा 12'});
      profileGate.complete({'displayName': 'विद्यार्थी'});
      final result = await pending;

      expect(result.profile?['displayName'], 'विद्यार्थी');
      expect(result.memory?['summary'], 'कक्षा 12');
      expect(result.profileError, isNull);
      expect(result.memoryError, isNull);
    });

}
